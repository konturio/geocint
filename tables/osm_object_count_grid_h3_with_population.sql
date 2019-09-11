drop table if exists osm_object_count_grid_h3_with_population;
create table osm_object_count_grid_h3_with_population as (
    select coalesce(a.resolution, b.resolution) as resolution,
           coalesce(count, 0)                   as count,
           coalesce(building_count, 0)          as building_count,
           coalesce(highway_length, 0)          as highway_length,
           coalesce(amenity_count, 0)           as amenity_count,
           coalesce(osm_users, 0)               as osm_users,
           coalesce(population, 0)              as population,
           hex.area / 1000000.0                 as area_km2,
           coalesce(a.resolution, b.resolution) as zoom,
           avg_ts                               as avg_ts,
           max_ts                               as max_ts,
           p90_ts                               as p90_ts,
           coalesce(a.h3, b.h3)                 as h3,
           hex.geom                             as geom
    from osm_object_count_grid_h3 a
             full outer join population_grid_h3 b on a.resolution = b.resolution and a.h3 = b.h3
             join ST_HexagonFromH3(coalesce(a.h3, b.h3)) hex on true
    order by resolution, geom
);

vacuum analyze osm_object_count_grid_h3_with_population;
create index on osm_object_count_grid_h3_with_population using gist (geom, zoom);
