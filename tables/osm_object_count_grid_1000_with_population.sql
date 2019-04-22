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
        7                                                                                 as zoom
    from
        osm_object_count_grid_1000 a
            full outer join ghs_population_grid_1000 b on a.geom::bytea = b.geom::bytea
    order by 1
);

create index on osm_object_count_grid_1000_with_population using brin(zoom);
-- for zoom 6
insert into osm_object_count_grid_1000_with_population
select
    ST_SnapToCellGrid(geom, 6) as geom,
    sum(count)                           as count,
    sum(building_count)                  as building_count,
    sum(highway_count)                   as highway_count,
    sum(highway_length)                  as highway_length,
    sum(amenity_count)                   as amenity_count,
    sum(natural_count)                   as natural_count,
    sum(landuse_count)                   as landuse_count,
    sum(population)                      as population,
    sum(area_km2)                        as area_km2,
    6                                    as zoom
from
    osm_object_count_grid_1000_with_population
where
    zoom = 7
group by 1;
-- for zoom 5
insert into osm_object_count_grid_1000_with_population
select
    ST_SnapToCellGrid(geom, 5) as geom,
    sum(count)                           as count,
    sum(building_count)                  as building_count,
    sum(highway_count)                   as highway_count,
    sum(highway_length)                  as highway_length,
    sum(amenity_count)                   as amenity_count,
    sum(natural_count)                   as natural_count,
    sum(landuse_count)                   as landuse_count,
    sum(population)                      as population,
    sum(area_km2)                        as area_km2,
    5                                    as zoom
from
    osm_object_count_grid_1000_with_population
where
    zoom = 6
group by 1;
-- for zoom  4
insert into osm_object_count_grid_1000_with_population
select
    ST_SnapToCellGrid(geom, 4) as geom,
    sum(count)                           as count,
    sum(building_count)                  as building_count,
    sum(highway_count)                   as highway_count,
    sum(highway_length)                  as highway_length,
    sum(amenity_count)                   as amenity_count,
    sum(natural_count)                   as natural_count,
    sum(landuse_count)                   as landuse_count,
    sum(population)                      as population,
    sum(area_km2)                        as area_km2,
    4                                    as zoom
from
    osm_object_count_grid_1000_with_population
where
    zoom = 5
group by 1;
-- for zoom 3
insert into osm_object_count_grid_1000_with_population
select
    ST_SnapToCellGrid(geom, 3) as geom,
    sum(count)                           as count,
    sum(building_count)                  as building_count,
    sum(highway_count)                   as highway_count,
    sum(highway_length)                  as highway_length,
    sum(amenity_count)                   as amenity_count,
    sum(natural_count)                   as natural_count,
    sum(landuse_count)                   as landuse_count,
    sum(population)                      as population,
    sum(area_km2)                        as area_km2,
    3                                    as zoom
from
    osm_object_count_grid_1000_with_population
where
    zoom = 4
group by 1;
-- for zoom 2
insert into osm_object_count_grid_1000_with_population
select
    ST_SnapToCellGrid(geom, 2) as geom,
    sum(count)                           as count,
    sum(building_count)                  as building_count,
    sum(highway_count)                   as highway_count,
    sum(highway_length)                  as highway_length,
    sum(amenity_count)                   as amenity_count,
    sum(natural_count)                   as natural_count,
    sum(landuse_count)                   as landuse_count,
    sum(population)                      as population,
    sum(area_km2)                        as area_km2,
    2                                    as zoom
from
    osm_object_count_grid_1000_with_population
where
    zoom = 3
group by 1;
-- for zoom 1
insert into osm_object_count_grid_1000_with_population
select
    ST_SnapToCellGrid(geom, 1) as geom,
    sum(count)                           as count,
    sum(building_count)                  as building_count,
    sum(highway_count)                   as highway_count,
    sum(highway_length)                  as highway_length,
    sum(amenity_count)                   as amenity_count,
    sum(natural_count)                   as natural_count,
    sum(landuse_count)                   as landuse_count,
    sum(population)                      as population,
    sum(area_km2)                        as area_km2,
    1                                    as zoom
from
    osm_object_count_grid_1000_with_population
where
    zoom = 2
group by 1;
-- for zoom 0
insert into osm_object_count_grid_1000_with_population
select
    ST_SnapToCellGrid(geom, 0) as geom,
    sum(count)                           as count,
    sum(building_count)                  as building_count,
    sum(highway_count)                   as highway_count,
    sum(highway_length)                  as highway_length,
    sum(amenity_count)                   as amenity_count,
    sum(natural_count)                   as natural_count,
    sum(landuse_count)                   as landuse_count,
    sum(population)                      as population,
    sum(area_km2)                        as area_km2,
    0                                    as zoom
from
    osm_object_count_grid_1000_with_population
where
    zoom = 1
group by 1;
-- create index
create index on osm_object_count_grid_1000_with_population using gist (geom);
