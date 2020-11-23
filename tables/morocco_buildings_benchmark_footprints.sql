-- Step 1. Area of interest for 2nd stage

--transform the geometry column into mercator
alter table morocco_buildings_benchmark
    rename column wkb_geometry to geom;
update morocco_buildings_benchmark
set geom = ST_Transform(ST_SetSRID(geom, 4326), 3857);

update morocco_buildings_benchmark
    set building_height = 10, is_confident = false
where building_height is null;

update morocco_buildings_benchmark
    set is_confident = false
where is_confident is null;

-- benchmark's area of interest, per city
drop table if exists morocco_buildings_benchmark_aoi;
create table morocco_buildings_benchmark_aoi as (
    select city,
           ST_Convexhull(ST_Collect(geom)) as geom
    from morocco_buildings_benchmark
    group by city
);

-- clip CV-detected buildings using the convex hull of manually mapped ones
drop table if exists morocco_buildings_benchmark_phase2;
create table morocco_buildings_benchmark_phase2 as (
    select height as building_height,
           ST_Intersection(ST_Transform(b.geom, 3857), a.geom) as geom,
           a.city
    from morocco_buildings                    b
         join morocco_buildings_benchmark_aoi a on ST_Intersects(b.geom, ST_Transform(a.geom, 4326))
);


-- Step 2. Convert roofprints to footprints
-- add footprint geometry column
alter table morocco_buildings_benchmark
    add column footprint geometry;

-- stitch together blocks of the same height to match them to similar blocks in other dataset
drop table if exists morocco_buildings_benchmark_union;
create table morocco_buildings_benchmark_union as (
    select (ST_Dump(ST_Union(ST_MakeValid(ST_SnapToGrid(geom, 0.1))))).geom  as geom,
           building_height,
           city
    from morocco_buildings_benchmark
    group by building_height, city
);

alter table morocco_buildings_benchmark_union
    add column phase_2 geometry;

-- match manually mapped roofprints cluster to a set of footprints right under it.
-- only constider a match if representative point of footprint is inside roofprint cluster.
update morocco_buildings_benchmark_union a
set phase_2 = (
    select ST_Union(geom)
    from morocco_buildings_benchmark_phase2 b
    where a.geom && b.geom
      and ST_Intersects(a.geom, ST_PointOnSurface(b.geom))
);

-- shift the roofprints to the corresponding centers of mass of computer-detected footprints
drop table if exists morocco_benchmark_shifts;
create table morocco_benchmark_shifts as (
    select city,
           -1 * percentile_cont(0.5) within group (
               order by (building_height / (ST_X(ST_Centroid(geom)) - ST_X(ST_Centroid(phase_2))))) as X,
           -1 * percentile_cont(0.5) within group (
               order by (building_height / (ST_Y(ST_Centroid(geom)) - ST_Y(ST_Centroid(phase_2))))) as Y
    from morocco_buildings_benchmark_union
    where phase_2 is not null
      and building_height > 10 -- low heights have higher uncertainty
    group by city
);

-- update footprint
update morocco_buildings_benchmark b
set footprint = ST_Translate(geom, building_height / s.x, building_height / s.y)
from ( select x, y, city
       from morocco_benchmark_shifts ) s
where b.city = s.city;
