drop table if exists morocco_buildings_benchmark_aoi;
create table morocco_buildings_benchmark_aoi as (
    select city,
           ST_Convexhull(ST_Collect(footprint)) as geom
    from morocco_buildings_benchmark
    group by city
);
