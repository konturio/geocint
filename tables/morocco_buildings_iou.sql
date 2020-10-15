-- Step 1. Area of interest for 2nd stage
-- extract valid geometry collection from morocco_buildings
drop table if exists morocco_buildings_valid;
create table morocco_buildings_valid as (
    select building_height,
           ST_CollectionExtract(ST_MakeValid(geom), 3) as geom
    from morocco_buildings
);

alter table morocco_buildings_valid
    add column city text;

-- label buildings according to cities
update morocco_buildings_valid
set city = (
    select city
    from morocco_buildings_benchmark
    where ST_Intersects(ST_PointOnSurface(wkb_geometry), (
        select ST_PointOnSurface(geom)
        from morocco_buildings_valid
    )
              )
);

-- benchmark's area of interest
drop table if exists morocco_buildings_benchmark_aoi;
create table morocco_buildings_benchmark_aoi as (
    select ST_Convexhull(ST_Collect(wkb_geometry)) as geom
    from morocco_buildings_benchmark
);

drop table if exists morocco_buildings_benchmark_phase2;
create table morocco_buildings_benchmark_phase2 as (
    select *
    from morocco_buildings_valid
    where ST_Intersects(geom, (
        select geom
        from morocco_buildings_benchmark_aoi
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
set geom = ST_Intersection(geom, (
    select geom
    from morocco_buildings_benchmark_aoi)
    );


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
           building_height,
           city
    from morocco_buildings_benchmark_phase2
    group by building_height, city
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

-- update footprints' geometry by shifting
update morocco_buildings_benchmark
set footprint = ST_Translate(wkb_geometry,
                             building_height / (select -1 * percentile_cont(0.5) within group (
                                 order by (building_height / (ST_X(ST_Centroid(geom)) - ST_X(ST_Centroid(phase_2)))))
                                                from morocco_buildings_benchmark_union),
                             building_height / (select -1 * percentile_cont(0.5) within group (
                                 order by (building_height / (ST_Y(ST_Centroid(geom)) - ST_Y(ST_Centroid(phase_2)))))
                                                from morocco_buildings_benchmark_union)
    )
where city = 'Agadir';

-- Step 3. IoU metrics
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
