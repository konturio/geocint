--Prepare osm_admin_boundaries_in with additional boundaries
drop table if exists osm_admin_boundaries_in;
create table osm_admin_boundaries_in as
        select * from osm_admin_boundaries
        union all
        -- Add 'Swalbard and Jan Mayen' and 'United States Minor Islands' boundary
        select max(o.osm_id)+1          as osm_id,
               null                     as osm_type,
               'iso'                    as boundary,
               null                     as admin_level,
               'Svalbard and Jan Mayen' as name,
               '{"name:en": "Svalbard and Jan Mayen", "wikidata": "Q842829", "ISO3166-2": "NO-SJ"}' as tags,
               a.geom                   as geom,
               null                     as kontur_admin_level
        from osm_admin_boundaries o,
             (select ST_Union(ST_Normalize(geog::geometry)) as geom from osm where osm_id in ('1337397','1337126') and osm_type = 'relation') a
             group by a.geom
        union all
        select max(o.osm_id)+2                        as osm_id,
               null                                   as osm_type,
               'iso'                                  as boundary,
               null                                   as admin_level,
               'United States Minor Outlying Islands' as name,
               '{"name:en": "United States Minor Outlying Islands", "wikidata": "Q16645", "ISO3166-2": "US-UM"}' as tags,
               b.geom                                 as geom,
               null                                   as kontur_admin_level
        from osm_admin_boundaries o,
             (select ST_Union(ST_Normalize(geog::geometry)) as geom
                  from osm where osm_id in ('8161698','6430384','7248458','12814070','7248454','7248460',
                                            '7248461','7248459','7248455','5748709','11212373') 
                                 and osm_type = 'relation') b
             group by b.geom;

-- Prepare subdivided osm admin boundaries table with index for further queries
drop table if exists osm_admin_subdivided_in;
create table osm_admin_subdivided_in as
select
        osm_id,
        ST_Subdivide(ST_Transform(geom, 3857)) as geom
from osm_admin_boundaries_in;
create index on osm_admin_subdivided_in using gist(geom);

-- Clipping Crimea from Russia boundary and South Federal County boundary by Ukraine border
-- To exclude Crimea population from Russia population calculation
with ukraine_border as (
    select ST_Transform(geom, 3857) geom
    from osm_admin_boundaries_in
    where osm_id = 60199
)
update osm_admin_subdivided_in k
        set geom = ST_Multi(ST_Difference(k.geom, u.geom))
        from ukraine_border u
        where k.osm_id in ('60189', '1059500');

-- Sum population from h3 to osm admin boundaries (rounding to integers)
drop table if exists osm_admin_boundaries_mid;
create table osm_admin_boundaries_mid as
with sum_population as (
        select
                b.osm_id,
                round(sum(h.population *
                        (case
                                when ST_Within(h.geom, b.geom) then 1
                                else ST_Area(ST_Intersection(h.geom, b.geom)) / ST_Area(h.geom)
                        end) -- Calculate intersection area for each h3 cell and boundary polygon
                )) as population
        from osm_admin_subdivided_in b
        join kontur_population_h3 h
                on ST_Intersects(h.geom, b.geom)
                        and h.resolution = 8
                                and h.population > 0
        group by b.osm_id
)
select
        b.osm_id,
        b.osm_type,
        b.boundary,
        case
            -- Special rule for Palestinian Territories - because of it's disputed status it often lacks admin_level key:
            when b.admin_level is null and b.tags @> '{"ISO3166-1":"PS"}' then '2'
            else b.admin_level
        end                                                             as admin_level,
        b.kontur_admin_level,
        coalesce(b.name, b.tags ->> 'int_name', b.tags ->> 'name:en')   as "name",         -- boundary name with graceful fallback
        b.tags,
        p.population,
        b.geom
from osm_admin_boundaries_in b
left join sum_population p using(osm_id);
create index on osm_admin_boundaries_mid using gist(geom, ST_Area(geom));

-- Drop temporary table
drop table if exists osm_admin_boundaries_in;

drop table if exists gadm_in;
create table gadm_in as (
        select distinct on (g.id)
                b.osm_id,
                g.id,
                g.hasc,
                g.gadm_level,
                b.iou
        from gadm_deduplicated g
        left join lateral (
                select
                        b.osm_id,
                        -- Calculate Intersection Over Union between OSM and GADM:
                        ST_Area(ST_Intersection(b.geom, g.geom))::numeric /
                        ST_Area(ST_Union(b.geom, g.geom)) as iou
                from osm_admin_boundaries_mid b
                where ST_Intersects(g.geom, b.geom) and ST_Area(b.geom) between 0.1 * ST_Area(g.geom) and 10 * ST_Area(g.geom)
        ) b on true
        order by g.id, b.iou desc
);

-- Join OSM admin boundaries and HASC codes based on max IOU
drop table if exists kontur_boundaries_in;
create table kontur_boundaries_in as
select distinct on (b.osm_id)
        b.osm_id,
        b.osm_type,
        g.id as gadm_id,
        b.boundary,
        b.admin_level,
        b.kontur_admin_level,
        b.name,
        coalesce(b.tags->>'name:en', b.tags->>'int_name') as name_en,
        g.hasc,
        g.gadm_level,
        g.iou as osm_gadm_iou,
        b.tags,
        b.population,
        b.geom
from osm_admin_boundaries_mid b
left join gadm_in g using(osm_id)
order by b.osm_id, g.hasc is not null desc, g.iou desc;


-- Join Wikidata HASC codes and population based on wikidata OSM tag
drop table if exists kontur_boundaries_mid;
create table kontur_boundaries_mid as
select k.*, 
       w.hasc                    as hasc_wiki,
       round(p.population)       as wiki_population
from kontur_boundaries_in k
left join wikidata_hasc_codes w
        on replace(w.wikidata_item, 'http://www.wikidata.org/entity/', '') = k.tags ->> 'wikidata'
left join wikidata_population p
        on replace(p.wikidata_item, 'http://www.wikidata.org/entity/', '') = k.tags ->> 'wikidata';

-- Drop temporary tables
drop table if exists osm_admin_subdivided_in;
drop table if exists osm_admin_boundaries_mid;
drop table if exists kontur_boundaries_in;

-- Special case for Soutern Federal District and Russia
update kontur_boundaries_mid
set wiki_population = 14044580
where osm_id = '1059500';

update kontur_boundaries_mid
set wiki_population = 143666931
where osm_id = '60189';

-- Clipping Crimea from Russia boundary and South Federal County boundary by Ukraine border
with ukraine_border as (
    select geom 
    from kontur_boundaries_mid
    where osm_id = 60199
)
update kontur_boundaries_mid k
        set geom = ST_Multi(ST_Difference(k.geom, u.geom))
        from ukraine_border u
        where k.osm_id in ('60189', '1059500');

-- Delete all boundaries, which contain in tags addr:country' = 'RU' or 'addr:postcode' 
-- first digit is 2 bcs all ukraineian postcode have 9 as first digit
delete from kontur_boundaries_mid 
        where ((tags ->> 'addr:country' = 'RU' 
                and admin_level::numeric > 3 )
                or (tags ->> 'addr:postcode' like '2%')) 
                and ST_Intersects(geom, ST_GeomFromText('POLYGON((32.00 46.50, 36.50 46.50, 
                                                                  36.65 45.37, 36.51 45.27, 
                                                                  36.50 44.00, 32.00 44.00, 
                                                                  32.0 46.5 ))', 4326));


------------ default language block ----------------

drop table if exists default_language_extrapolated_from_sub_country_relations;
create table default_language_extrapolated_from_sub_country_relations as (
    select distinct on (b.osm_id) b.osm_id,
                                  d.default_language
    from kontur_boundaries_mid b,
         default_language_relations d 
    where not b.tags ? 'default_language'
          and ST_Intersects(ST_PointOnSurface(b.geom), d.geom)
          and ST_Area(b.geom)/d.area < 2
    order by b.osm_id, 
             1 - abs(ST_Area(b.geom)/d.area) asc
);

drop table if exists default_language_extrapolated_from_country_relations;
create table default_language_extrapolated_from_country_relations as (
    select distinct b.osm_id,
                    d.default_language
    from kontur_boundaries_mid b,
         default_language_relations_adm_2 d 
    where not b.tags ? 'default_language'
          and ST_Intersects(ST_PointOnSurface(b.geom), d.geom)
          and b.osm_id not in (select osm_id from default_language_extrapolated_from_sub_country_relations)
);

drop table if exists boundaries_with_default_language;
create table boundaries_with_default_language as (
    select osm_id,
           default_language
    from default_language_relations_with_admin_level
    union all 
    select osm_id,
           default_language
    from default_language_relations_without_admin_level
);

drop table if exists kontur_boundaries;
create table kontur_boundaries as (
    select distinct on (b.osm_id) b.*,
                             coalesce(p.lang, l.default_language, n.default_language, m.default_language, 'en'::text) as default_language
    from kontur_boundaries_mid b
         left join default_language_extrapolated_from_sub_country_relations n on b.osm_id = n.osm_id
         left join default_language_extrapolated_from_country_relations m on b.osm_id = m.osm_id
         left join boundaries_with_default_language l on b.osm_id = l.osm_id
         left join default_languages_2_level p on b.osm_id = p.osm_id
    order by osm_id
);

-- drop temporary tables
drop table if exists default_language_extrapolated_from_sub_country_relations;
drop table if exists default_language_extrapolated_from_country_relations;
drop table if exists boundaries_with_default_language;

-- Add index for join with using hasc
create index on kontur_boundaries using btree(hasc_wiki);