drop table if exists morocco_buildings_benchmark_aoi;
create table morocco_buildings_benchmark_aoi as (
    select city,
           ST_Convexhull(ST_Collect(ST_Transform(footprint, 3857))) as geom
    from morocco_buildings_manual
    group by city
);
