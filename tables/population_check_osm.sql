drop table if exists population_check_osm;
create table population_check_osm as (
    select osm_id,
           name,
           kontur_pop                        "kontur_pop",
           osm_pop,
           diff_pop,
           diff_pop / (kontur_pop + osm_pop) "index",
           geom
    from kontur_boundaries b,
         parse_float(tags ->> 'population') osm_pop,
         coalesce(b.population, 0) kontur_pop,
         abs(kontur_pop - osm_pop) "diff_pop",
         ST_Area(geom::geography) "area"
    where osm_pop > 0
      and gadm_level = 0
      and area > 5161293.2 -- average hexagon area at 7 resolution
    order by "index" desc
);

create index on population_check_osm using gist (geom);