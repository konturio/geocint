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
           round(osm_pop - b.population)                                                                 as "Population difference",

           -- (b.population + 1) to prevent "2201E: cannot take logarithm of zero" when b.population = 0:
           round(abs(log(osm_pop) - log(b.population + 1))::numeric, 2)                                  as diff_log
    from kontur_boundaries b,
         parse_float(tags ->> 'population') osm_pop,
         ST_Area(geom::geography) "area"
    where osm_pop > 0
      and population is not null
      -- exclude boundaries with a small area (for example, the Vatican City)
      and area > 737327.6 -- average hexagon area at 8 resolution
    order by "diff_log" desc
);

-- Update timestamp in reports table (for further export to reports API JSON):
update osm_reports_list
set last_updated = (select meta->'data'->'timestamp'->>'last' as updated from osm_meta)
where id = 'population_tag_check';
