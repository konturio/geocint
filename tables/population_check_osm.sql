drop table if exists population_check_osm;
create table population_check_osm as (
    select
            -- Generate link to object properties on osm.org:
           'href_[' || osm_id || '](https://www.openstreetmap.org/' || osm_type || '/' || osm_id || ')'  as "OSM id",

            -- Generate link for JOSM remote desktop:
           'hrefIcon_[' || coalesce(tags ->> 'name:en', tags ->> 'int_name', name) ||
           '](http://localhost:8111/load_object?new_layer=false&objects=' ||
           left(osm_type, 1) || osm_id || '&relation_members=true)'                                      as "Name",

           tags ->> 'population:date'                                                                    as "OSM population date",
           round(osm_pop)                                                                                as "OSM population",
           round(b.population)                                                                           as "Kontur population",
           b.wiki_population                                                                             as "Wikidata population",
           round(osm_pop - b.population)                                                                 as "OSM-Kontur Population difference",
           -- if wiki_population is null return null
           round(b.wiki_population - b.population)                                                       as "Wikidata-Kontur Population difference"
    from kontur_boundaries b,
         parse_float(tags ->> 'population') osm_pop,
         ST_Area(geom::geography) "area"
    where osm_pop > 0
      and population is not null
      -- exclude boundaries with a small area (for example, the Vatican City)
      and area > 737327.6 -- average hexagon area at 8 resolution
    order by "OSM-Kontur Population difference" desc
);

-- Update timestamp in reports table (for further export to reports API JSON):
update osm_reports_list
set last_updated = (select meta->'data'->'timestamp'->>'last' as updated from osm_meta)
where id = 'population_tag_check';
