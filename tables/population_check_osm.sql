drop table if exists population_check_osm_in;
create table population_check_osm_in as (
    select
            osm_id                                                                                        as osm_id,
            osm_type                                                                                      as osm_type,
            name                                                                                          as name_boundaries,
            coalesce(name_en, name)                                                                       as name_en,
            null::text                                                                                    as country,
            null::text                                                                                    as hasc_wiki,       
           
            -- Generate link to object properties on osm.org:
            'href_[' || osm_id || '](https://www.openstreetmap.org/' || osm_type || '/' || osm_id || ')'  as report_osm_id,

            -- Generate link for JOSM remote desktop:
            'hrefIcon_[' || coalesce(tags ->> 'name:en', tags ->> 'int_name', name) ||
            '](http://127.0.0.1:8111/load_object?new_layer=false&objects=' ||
            left(osm_type, 1) || osm_id || '&relation_members=true)'                                      as report_name,

            tags ->> 'population:date'                                                                    as report_osm_date,
            round(osm_pop)                                                                                as report_osm_pop,
            round(b.population)                                                                           as report_kontur_pop,
            b.wiki_population                                                                             as report_wiki_pop,
            round(osm_pop - b.population)                                                                 as report_osm_kontur_diff,
            -- if wiki_population is null return null
            round(b.wiki_population - b.population)                                                       as report_wiki_kontur_diff,
            case
                when b.tags ? 'wikidata'
                    then 'http://www.wikidata.org/entity/' || (b.tags ->> 'wikidata')::text
                    else null
            end                                                                                           as wikidata_link,
            ST_PointOnSurface(geom)                                                                       as geom
    from kontur_boundaries b,
         parse_float(tags ->> 'population') osm_pop,
         ST_Area(geom::geography) "area"
    where osm_pop > 0
      and population is not null
      -- exclude boundaries with a small area (for example, the Vatican City)
      and area > 737327.6 -- average hexagon area at 8 resolution
);

-- We need for update bcs some boundaries have point on surface out of any countries geom
update population_check_osm_in p
    set country = c.name,
        hasc_wiki = c.hasc_wiki
    from hdx_boundaries c
    where ST_Intersects(c.geom, p.geom);

-- Set final column nanes and remove potential duplicates for disputed area
drop table if exists population_check_osm;
create table population_check_osm as (
    select  distinct on (p.osm_id)
            p.osm_id                                                                                      as osm_id,
            p.name_boundaries                                                                             as name_boundaries,
            p.name_en                                                                                     as name_en,
            p.wikidata_link                                                                               as wikidata_link,
            p.report_osm_id                                                                               as "OSM id",
            p.country                                                                                     as "Country",
            p.report_name                                                                                 as "Name",
            p.report_osm_date                                                                             as "OSM population date",
            p.report_osm_pop                                                                              as "OSM population",
            p.report_kontur_pop                                                                           as "Kontur population",
            k.right_population                                                                            as "Expected population",
            p.report_wiki_pop                                                                             as "Wikidata population",
            p.report_osm_kontur_diff                                                                      as "OSM-Kontur Population difference",
            p.report_wiki_kontur_diff                                                                     as "Wikidata-Kontur Population difference",
            k.right_population - p.report_kontur_pop                                                      as expected_kontur_diff,
            case
                when k.right_population is not null and k.right_population != 0
                    then round(cast((k.right_population - p.report_kontur_pop)/k.right_population *100 as numeric) ,2) 
                    else null 
            end as "Expected-Kontur difference percent",
            case
                when p.report_osm_pop is not null and p.report_osm_pop != 0
                    then round(cast((p.report_osm_pop - p.report_kontur_pop)/p.report_osm_pop *100 as numeric) ,2)
                    else null
            end as "OSM-Kontur difference percent",
            case
                when p.report_wiki_pop is not null and p.report_wiki_pop != 0
                    then round(cast((p.report_wiki_pop - p.report_kontur_pop)/p.report_wiki_pop *100 as numeric) ,2)
                    else null
            end as "Wikidata-Kontur difference percent"
    from population_check_osm_in p
         left join prescale_to_osm k
         on p.osm_id = k.osm_id
    order by 1
);

-- Drop temporary table
drop table if exists population_check_osm_in;