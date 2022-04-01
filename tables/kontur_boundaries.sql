-- Prepare subdivided osm admin boundaries table with index for further queries
drop table if exists osm_admin_subdivided_in;
create table osm_admin_subdivided_in as
select
        osm_id,
        ST_Subdivide(ST_Transform(geom, 3857)) as geom
from osm_admin_boundaries;
create index on osm_admin_subdivided_in using gist(geom);

-- Clipping Crimea from Russia boundary and South Federal County boundary by Ukraine border
-- To exclude Crimea population from Russia population calculation
with ukraine_border as (
    select ST_Transform(geom, 3857) geom
    from osm_admin_boundaries
    where osm_id = 60199
)
update osm_admin_subdivided_in k
        set geom = ST_Multi(ST_Difference(k.geom, u.geom))
        from ukraine_border u
        where k.osm_id in ('60189', '1059500');

-- Sum population from h3 to osm admin boundaries (rounding to integers)
drop table if exists osm_admin_boundaries_in;
create table osm_admin_boundaries_in as
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
from osm_admin_boundaries b
left join sum_population p using(osm_id);
create index on osm_admin_boundaries_in using gist(geom, ST_Area(geom));


-- Join OSM admin boundaries and HASC codes based on max IOU
drop table if exists kontur_boundaries_in;
create table kontur_boundaries_in as
with gadm_in as (
        select  b.osm_id,
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
                from (
                        select b.osm_id, b.geom
                        from osm_admin_boundaries_in b
                        where ST_Area(b.geom) between 0.1 * ST_Area(g.geom) and 10 * ST_Area(g.geom)
                                and (g.geom && b.geom)
                        order by abs(ST_Area(b.geom) - ST_Area(g.geom))
                        offset 0
                ) b
                where ST_Intersects(g.geom, b.geom)
                order by 2 desc
                limit 1
        ) b on true
        order by g.geom, g.gadm_level
)
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
from osm_admin_boundaries_in b
left join gadm_in g using(osm_id)
order by b.osm_id, g.hasc is not null desc, g.iou desc;


-- Join Wikidata HASC codes based on wikidata OSM tag
drop table if exists kontur_boundaries;
create table kontur_boundaries as
select k.*, 
       w.hasc                    as hasc_wiki,
       round(p.max_population)   as max_wiki_population
from kontur_boundaries_in k
left join wikidata_hasc_codes w
        on replace(w.wikidata_item, 'http://www.wikidata.org/entity/', '') = k.tags ->> 'wikidata'
left join wikidata_population p
        on replace(p.wikidata_item, 'http://www.wikidata.org/entity/', '') = k.tags ->> 'wikidata';

-- Drop temporary tables
drop table if exists osm_admin_subdivided_in;
drop table if exists osm_admin_boundaries_in;
drop table if exists kontur_boundaries_in;

-- Special case for Soutern Federal District and Russia
update kontur_boundaries
set max_wiki_population = 14044580
where osm_id = '1059500';

update kontur_boundaries
set max_wiki_population = 143666931
where osm_id = '60189';

-- Clipping Crimea from Russia boundary and South Federal County boundary by Ukraine border
with ukraine_border as (
    select geom 
    from kontur_boundaries
    where osm_id = 60199
)
update kontur_boundaries k
        set geom = ST_Multi(ST_Difference(k.geom, u.geom))
        from ukraine_border u
        where k.osm_id in ('60189', '1059500');

-- Delete all boundaries, which contain in tags addr:country' = 'RU' or 'addr:postcode' 
-- first digit is 2 bcs all ukraineian postcode have 9 as first digit
delete from kontur_boundaries 
        where ((tags ->> 'addr:country' = 'RU' 
                and admin_level::numeric > 3 )
                or (tags ->> 'addr:postcode' like '2%')) 
                and ST_Intersects(geom, ST_GeomFromText('POLYGON((32.00 46.50, 36.50 46.50, 
                                                                  36.65 45.37, 36.51 45.27, 
                                                                  36.50 44.00, 32.00 44.00, 
                                                                  32.0 46.5 ))', 4326));