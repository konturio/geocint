drop table if exists population_check_osm;
create table population_check_osm as (
    select osm_id,
           b.tags ->> 'ISO3166-1:alpha3'       "iso",
           name,
           tags ->> 'name:en'                  "name_en",
           tags ->> 'population:date'          "pop_date",
           osm_pop,
           b.population                        "kontur_pop",
           diff_pop,
           diff_pop / (b.population + osm_pop) "index",
           exists(
                   select
                   from hrsl_population_boundary h
                   where h.iso = b.tags ->> 'ISO3166-1:alpha3'
               )                               "has_hrsl_coverage"
    from kontur_boundaries b,
         parse_float(tags ->> 'population') osm_pop,
         abs(b.population - osm_pop) "diff_pop",
         ST_Area(geom::geography) "area"
    where osm_pop > 0
      and admin_level = '2'
      -- exclude boundaries with a small area (for example, the Vatican City)
      and area > 737327.6 -- average hexagon area at 8 resolution
    order by "index" desc
);
