drop table if exists osm_object_count_grid_1000_with_population;
create table osm_object_count_grid_1000_with_population as (
    select
        coalesce(a.geom, b.geom)                                                          as geom,
        coalesce(count, 0)                                                                as count,
        coalesce(building_count, 0)                                                       as building_count,
        coalesce(highway_count, 0)                                                        as highway_count,
        coalesce(highway_length, 0)                                                       as highway_length,
        coalesce(amenity_count, 0)                                                        as amenity_count,
        coalesce(natural_count, 0)                                                        as natural_count,
        coalesce(landuse_count, 0)                                                        as landuse_count,
        coalesce(population, 0)                                                           as population,
        ST_Area(ST_Transform(coalesce(a.geom, b.geom), 4326)::geography)::float / 1000000 as area_km2,
        1000                                                                              as resolution,
        8                                                                                 as zoom
    from
        osm_object_count_grid_1000 a
            full outer join ghs_population_grid_1000 b on a.geom::bytea = b.geom::bytea
    order by 1
);
-- for resolution 2000
insert into osm_object_count_grid_1000_with_population
select
    ST_Expand(ST_SnapToGrid(ST_Centroid(geom), 2000), 1000) as geom,
    sum(count)                                              as count,
    sum(building_count)                                     as building_count,
    sum(highway_count)                                      as highway_count,
    sum(highway_length)                                     as highway_length,
    sum(amenity_count)                                      as amenity_count,
    sum(natural_count)                                      as natural_count,
    sum(landuse_count)                                      as landuse_count,
    sum(population)                                         as population,
    sum(area_km2)                                           as area_km2,
    2000                                                    as resolution,
    7                                                       as zoom
from
    osm_object_count_grid_1000_with_population
group by 1;
-- for resolution 4000
insert into osm_object_count_grid_1000_with_population
select
    ST_Expand(ST_SnapToGrid(ST_Centroid(geom), 4000), 2000) as geom,
    sum(count)                                              as count,
    sum(building_count)                                     as building_count,
    sum(highway_count)                                      as highway_count,
    sum(highway_length)                                     as highway_length,
    sum(amenity_count)                                      as amenity_count,
    sum(natural_count)                                      as natural_count,
    sum(landuse_count)                                      as landuse_count,
    sum(population)                                         as population,
    sum(area_km2)                                           as area_km2,
    4000                                                    as resolution,
    6                                                       as zoom
from
    osm_object_count_grid_1000_with_population
where
    resolution = 2000
group by 1;
-- for resolution 8000
insert into osm_object_count_grid_1000_with_population
select
    ST_Expand(ST_SnapToGrid(ST_Centroid(geom), 8000), 4000) as geom,
    sum(count)                                              as count,
    sum(building_count)                                     as building_count,
    sum(highway_count)                                      as highway_count,
    sum(highway_length)                                     as highway_length,
    sum(amenity_count)                                      as amenity_count,
    sum(natural_count)                                      as natural_count,
    sum(landuse_count)                                      as landuse_count,
    sum(population)                                         as population,
    sum(area_km2)                                           as area_km2,
    8000                                                    as resolution,
    5                                                       as zoom
from
    osm_object_count_grid_1000_with_population
where
    resolution = 4000
group by 1;
-- for resolution 16000
insert into osm_object_count_grid_1000_with_population
select
    ST_Expand(ST_SnapToGrid(ST_Centroid(geom), 16000), 8000) as geom,
    sum(count)                                               as count,
    sum(building_count)                                      as building_count,
    sum(highway_count)                                       as highway_count,
    sum(highway_length)                                      as highway_length,
    sum(amenity_count)                                       as amenity_count,
    sum(natural_count)                                       as natural_count,
    sum(landuse_count)                                       as landuse_count,
    sum(population)                                          as population,
    sum(area_km2)                                            as area_km2,
    16000                                                    as resolution,
    4                                                        as zoom
from
    osm_object_count_grid_1000_with_population
where
    resolution = 8000
group by 1;
-- for resolution 32000
insert into osm_object_count_grid_1000_with_population
select
    ST_Expand(ST_SnapToGrid(ST_Centroid(geom), 32000), 16000) as geom,
    sum(count)                                                as count,
    sum(building_count)                                       as building_count,
    sum(highway_count)                                        as highway_count,
    sum(highway_length)                                       as highway_length,
    sum(amenity_count)                                        as amenity_count,
    sum(natural_count)                                        as natural_count,
    sum(landuse_count)                                        as landuse_count,
    sum(population)                                           as population,
    sum(area_km2)                                             as area_km2,
    32000                                                     as resolution,
    3                                                         as zoom
from
    osm_object_count_grid_1000_with_population
where
    resolution = 16000
group by 1;
-- for resolution 64000
insert into osm_object_count_grid_1000_with_population
select
    ST_Expand(ST_SnapToGrid(ST_Centroid(geom), 64000), 32000) as geom,
    sum(count)                                                as count,
    sum(building_count)                                       as building_count,
    sum(highway_count)                                        as highway_count,
    sum(highway_length)                                       as highway_length,
    sum(amenity_count)                                        as amenity_count,
    sum(natural_count)                                        as natural_count,
    sum(landuse_count)                                        as landuse_count,
    sum(population)                                           as population,
    sum(area_km2)                                             as area_km2,
    64000                                                     as resolution,
    2                                                         as zoom
from
    osm_object_count_grid_1000_with_population
where
    resolution = 32000
group by 1;
-- for resolution 128000
insert into osm_object_count_grid_1000_with_population
select
    ST_Expand(ST_SnapToGrid(ST_Centroid(geom), 128000), 64000) as geom,
    sum(count)                                                 as count,
    sum(building_count)                                        as building_count,
    sum(highway_count)                                         as highway_count,
    sum(highway_length)                                        as highway_length,
    sum(amenity_count)                                         as amenity_count,
    sum(natural_count)                                         as natural_count,
    sum(landuse_count)                                         as landuse_count,
    sum(population)                                            as population,
    sum(area_km2)                                              as area_km2,
    128000                                                     as resolution,
    1                                                          as zoom
from
    osm_object_count_grid_1000_with_population
where
    resolution = 64000
group by 1;
-- create index
create index on osm_object_count_grid_1000_with_population using gist (geom);
