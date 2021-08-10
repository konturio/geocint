drop table if exists population_check_osm;
create table population_check_osm as (
    select osm_id,
           name,
           tags ->> 'name:en'                  "name_en",
           tags ->> 'population:date'          "pop_date",
           osm_pop,
           b.population                        "kontur_pop",
           osm_pop - b.population              "diff_pop",
           abs(log(osm_pop) - log(population)) "diff_log"
    from kontur_boundaries b,
         parse_float(tags ->> 'population') osm_pop,
         ST_Area(geom::geography) "area"
    where osm_pop > 0
      and population is not null
      -- exclude boundaries with a small area (for example, the Vatican City)
      and area > 737327.6 -- average hexagon area at 8 resolution
    order by "diff_log" desc
);
