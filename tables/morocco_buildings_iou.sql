-- Step 1. Area of interest for 2nd stage
-- benchmark's area of interest
drop table if exists morocco_buildings_benchmark_aoi;
create table morocco_buildings_benchmark_aoi as (
    select ST_Convexhull(ST_Collect(wkb_geometry)) as geom
    from morocco_buildings_benchmark
    group by city
);

drop table if exists morocco_buildings_benchmark_aoi_union;
create table morocco_buildings_benchmark_aoi_union as (
    select ST_Union(geom) from morocco_buildings_benchmark_aoi);

drop table if exists morocco_buildings_benchmark_phase2;
create table morocco_buildings_benchmark_phase2 as (
    select *
    from morocco_buildings_valid
    where ST_Intersects(geom, (
        select geom
        from morocco_buildings_benchmark_aoi_union
    )
              )
);

-- geometry transformations for shift calculations
update morocco_buildings_benchmark
set wkb_geometry = ST_Transform(wkb_geometry, 3857);

update morocco_buildings_benchmark_aoi
set geom = ST_Transform(geom, 3857);

update morocco_buildings_benchmark_phase2
set geom = ST_Transform(geom, 3857);

update morocco_buildings_benchmark_phase2
set geom = (ST_Intersection(geom, (
    select geom
    from morocco_buildings_benchmark_aoi_union)
    ));


-- Step 2. Convert roofprints to footprints
-- add footprint geometry column
alter table morocco_buildings_benchmark
    add column footprint geometry;

update morocco_buildings_benchmark
set footprint = wkb_geometry;

drop table if exists morocco_buildings_benchmark_union;
create table morocco_buildings_benchmark_union as (
    select (ST_Dump(ST_Union(wkb_geometry))).geom as geom,
           building_height,
           city
    from morocco_buildings_benchmark
    group by building_height, city
);

drop table if exists morocco_buildings_benchmark_phase2_union;
create table morocco_buildings_benchmark_phase2_union as (
    select (ST_Dump(
            ST_Union(geom))).geom as geom,
           building_height
    from morocco_buildings_benchmark_phase2
    group by building_height
);

alter table morocco_buildings_benchmark_union
    add column phase_2 geometry;

update morocco_buildings_benchmark_union a
set phase_2 = (
    select ST_Union(geom)
    from morocco_buildings_benchmark_phase2 b
    where ST_Intersects(a.geom, ST_PointOnSurface(b.geom)
              )
);

drop table if exists morocco_benchmark_shifts;
create table morocco_benchmark_shifts as (
    select city,
           -1 * percentile_cont(0.5) within group (
               order by (building_height / (ST_X(ST_Centroid(geom)) - ST_X(ST_Centroid(phase_2))))) as X,
           -1 * percentile_cont(0.5) within group (
               order by (building_height / (ST_Y(ST_Centroid(geom)) - ST_Y(ST_Centroid(phase_2))))) as Y
    from morocco_buildings_benchmark_union
    group by city
);

-- сalculate 2D IoU for all buildings
select ST_Area(
               ST_Intersection(
                           (select ST_Union(footprint) from morocco_buildings_benchmark),
                           (select ST_Union(geom) from morocco_buildings_benchmark_phase2)
                   )
           ) / ST_Area(
               ST_Union(
                           (select ST_Union(footprint) from morocco_buildings_benchmark),
                           (select ST_Union(geom) from morocco_buildings_benchmark_phase2)
                   )
           );
