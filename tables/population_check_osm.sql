drop table if exists population_check_osm_in;
create table population_check_osm_in as (
    select
           osm_id                                                                                        as osm_id,
           name                                                                                          as name_boundaries,
           coalesce(name_en, name)                                                                       as name_en,
           null::text                                                                                    as country,
           null::text                                                                                    as hasc_wiki,       
           
           -- Generate link to object properties on osm.org:
           'href_[' || osm_id || '](https://www.openstreetmap.org/' || osm_type || '/' || osm_id || ')'  as report_osm_id,

           -- Generate link for JOSM remote desktop:
           'hrefIcon_[' || coalesce(tags ->> 'name:en', tags ->> 'int_name', name) ||
           '](http://localhost:8111/load_object?new_layer=false&objects=' ||
           left(osm_type, 1) || osm_id || '&relation_members=true)'                                      as report_name,

           tags ->> 'population:date'                                                                    as report_osm_date,
           round(osm_pop)                                                                                as report_osm_pop,
           round(b.population)                                                                           as report_kontur_pop,
           b.wiki_population                                                                             as report_wiki_pop,
           round(osm_pop - b.population)                                                                 as report_osm_kontur_diff,
           -- if wiki_population is null return null
           round(b.wiki_population - b.population)                                                       as report_wiki_kontur_diff,
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
    select distinct on (osm_id)
           osm_id                  as osm_id,
           name_boundaries         as name_boundaries,
           name_en                 as name_en,
           report_osm_id           as "OSM id",
           country                 as "Country",
           report_name             as "Name",
           report_osm_date         as "OSM population date",
           report_osm_pop          as "OSM population",
           report_kontur_pop       as "Kontur population",
           report_wiki_pop         as "Wikidata population",
           report_osm_kontur_diff  as "OSM-Kontur Population difference",
           report_wiki_kontur_diff as "Wikidata-Kontur Population difference"
    from population_check_osm_in
    order by osm_id
);

-- Drop temporary table
drop table if exists population_check_osm_in;