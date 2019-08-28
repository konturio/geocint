drop table if exists osm_object_count_grid_h3_with_population;
create table osm_object_count_grid_h3_with_population as (
    select hex.geom                                 as geom,
           coalesce(a.h3, b.h3)                     as h3,
           coalesce(a.resolution, b.resolution)     as resolution,
           coalesce(count, 0)                       as count,
           coalesce(building_count, 0)              as building_count,
           coalesce(highway_length, 0)              as highway_length,
           coalesce(amenity_count, 0)               as amenity_count,
           --coalesce(highway_count, 0)                                                        as highway_count,
           --coalesce(natural_count, 0)                                                        as natural_count,
           --coalesce(landuse_count, 0)                                                        as landuse_count,
           coalesce(osm_users, 0)                   as osm_users,
           coalesce(population, 0)                  as population,
           hex.area::float / 1000000                as area_km2,
           coalesce(a.resolution, b.resolution) + 1 as zoom
    from osm_object_count_grid_h3 a
             full outer join population_grid_h3 b on a.resolution = b.resolution and a.h3 = b.h3
             join ST_HexagonFromH3(coalesce(a.h3, b.h3)) hex on true
    order by 1
);

vacuum analyze osm_object_count_grid_h3_with_population;
-- create index
create index on osm_object_count_grid_h3_with_population using gist (geom, zoom);
