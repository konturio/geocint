-- Step 1. Area of interest for 2nd stage

--transform the geometry column into mercator
alter table morocco_buildings_benchmark
    rename column wkb_geometry to geom;
update morocco_buildings_benchmark
set geom = ST_Transform(ST_SetSRID(geom, 4326), 3857);

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
    select building_height,
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
    select (ST_Dump(ST_Union(geom))).geom as geom,
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

drop table morocco_buildings_benchmark_union;
-- update footprint
update morocco_buildings_benchmark b
set footprint = ST_Translate(geom, building_height / s.x, building_height / s.y)
from ( select x, y, city
       from morocco_benchmark_shifts ) s
where b.city = s.city;


-- benchmark's area of interest, per city, now using footprints
drop table if exists morocco_buildings_benchmark_aoi;
create table morocco_buildings_benchmark_aoi as (
    select city,
           ST_Convexhull(ST_Collect(footprint)) as geom
    from morocco_buildings_benchmark
    group by city
);

-- clip CV-detected buildings using the convex hull of manually mapped ones
drop table if exists morocco_buildings_benchmark_phase2;
create table morocco_buildings_benchmark_phase2 as (
    select building_height,
           ST_Intersection(ST_Transform(b.geom, 3857), a.geom) as geom,
           a.city
    from morocco_buildings                    b
         join morocco_buildings_benchmark_aoi a on ST_Intersects(b.geom, ST_Transform(a.geom, 4326))
);

-- round the coordinates a little bit to make intersection/union more robust
update morocco_buildings_benchmark
set footprint = ST_CollectionExtract(ST_MakeValid(ST_Segmentize(ST_SnapToGrid(ST_Transform(ST_Simplify(footprint, 0), 3857), 0.031415926), 5)), 3);
update morocco_buildings_benchmark_phase2
set geom = ST_CollectionExtract(ST_MakeValid(ST_Segmentize(ST_SnapToGrid(ST_Transform(ST_Simplify(geom, 0), 3857), 0.031415926), 5)), 3);

-- calculate 2D IoU for each city separately
select humans.city as "City",
       ST_Area(ST_Intersection(footprint, geom)) /
       ST_Area(ST_Union(footprint, geom)) as "2D IoU"
from ( select city, ST_Union(footprint) as footprint from morocco_buildings_benchmark group by city )   as humans
     join ( select city, ST_Union(geom) as geom from morocco_buildings_benchmark_phase2 group by city ) as computers
          on humans.city = computers.city;

-- сalculate 3D IoU for all buildings
drop table if exists morocco_buildings_polygons_ph2;
create table morocco_buildings_polygons_ph2 as (
    select city, footprint as geom
    from morocco_buildings_benchmark
    union all
    select city, geom
    from morocco_buildings_benchmark_phase2
);

select distinct ST_Dimension(ST_Boundary(geom))
    from morocco_buildings_polygons_ph2;

delete
from morocco_buildings_polygons_ph2
where ST_Dimension(ST_Boundary(geom)) is null;

delete
from morocco_buildings_polygons_ph2
where ST_Dimension(ST_Boundary(geom)) = 2;

-- generate the breakout table with polygons of all candidate pieces
drop table if exists morocco_buildings_linework_ph2;
-- create table morocco_buildings_linework_ph2 as
-- with morocco_buildings_edges as (
--     select (ST_Dump(ST_UnaryUnion(ST_Node(ST_Collect(ST_Boundary(geom)))))).geom
--     from morocco_buildings_polygons_ph2
-- )
-- select (ST_Dump(ST_Polygonize(geom))).geom
-- from morocco_buildings_edges;

-- create table morocco_buildings_linework_ph2 as
-- with morocco_buildings_edges as (
--     select (ST_Dump(ST_UnaryUnion(ST_Collect(ST_Boundary(geom))))).geom
--     from morocco_buildings_polygons_ph2
-- )
--          select (ST_Dump(ST_Polygonize(ST_MakeValid(geom)))).geom
--          from morocco_buildings_edges;

create table morocco_buildings_linework_ph2 as
with morocco_buildings_edges as (
    select (ST_Dump(ST_UnaryUnion(ST_Collect(ST_Boundary(geom))))).geom
    from morocco_buildings_polygons_ph2
),
     morocco_buildings_parts as (
         select (ST_Dump(ST_Polygonize(ST_MakeValid(geom)))).geom
         from morocco_buildings_edges
     )
select *
from morocco_buildings_parts;

-- add columns with min and max building height values and zero them out
alter table morocco_buildings_linework_ph2
    add column min_height float;
alter table morocco_buildings_linework_ph2
    add column max_height float;
update morocco_buildings_linework_ph2
set min_height = 0,
    max_height = 0;

create index on morocco_buildings_benchmark_phase2 using gist(geom);
create index on morocco_buildings_benchmark using gist(footprint);

-- for each piece, get heights from both datasets. will swap them later.
update morocco_buildings_linework_ph2 a
set min_height = (
    select max(building_height)
    from morocco_buildings_benchmark_phase2 b
    where ST_Intersects(ST_PointOnSurface(a.geom), b.geom)
);

update morocco_buildings_linework_ph2 a
set max_height = (
    select max(building_height)
    from morocco_buildings_benchmark b
    where ST_Intersects(ST_PointOnSurface(a.geom), b.footprint)
);

-- replace NULLs with 0's
update morocco_buildings_linework_ph2
set min_height = 0
where min_height is null;
update morocco_buildings_linework_ph2
set max_height = 0
where max_height is null;

-- swap min and max to be correct
update morocco_buildings_linework_ph2
set min_height = least(min_height, max_height),
    max_height = greatest(max_height, min_height);


-- Step 3. Calculate IoU in 2D and 3D
-- 2D IoU: 0.661
select sum(ST_Area(geom)) filter (where min_height > 0) / sum(ST_Area(geom)) as IoU
from morocco_buildings_linework_ph2;
-- calculate IoU metrics for all 3D buildings: 0.478
select sum(min_height * ST_Area(geom)) / sum(max_height * ST_Area(geom))
from morocco_buildings_linework_ph2;


-- Step 4. Generate feature-to-feature IoU.

-- table for the matching geometries
drop table if exists morocco_buildings_iou_feature;
create table morocco_buildings_iou_feature as (
    select distinct footprint as geom_morocco_buildings,
           building_height as building_height_morocco_buildings,
           null::geometry as geom_phase2,
           null::float as building_height_phase2
    from morocco_buildings_benchmark
);

-- match geometries if representative point on one is insede other and vice versa.
-- in case of collision take option with better IoU.
update morocco_buildings_iou_feature a
set geom_phase2 = (
    select geom
    from morocco_buildings_benchmark_phase2 b
    where ST_Intersects(ST_PointOnSurface(a.geom_morocco_buildings), b.geom)
      and ST_Intersects(ST_PointOnSurface(b.geom), a.geom_morocco_buildings)
    order by (ST_Area(ST_Intersection(a.geom_morocco_buildings, b.geom)) /
              ST_Area(ST_Union(a.geom_morocco_buildings, b.geom))) desc
    limit 1
);

update morocco_buildings_iou_feature a
set building_height_phase2 = (
    select building_height
    from morocco_buildings_benchmark_phase2 b
    where ST_Intersects(ST_PointOnSurface(a.geom_morocco_buildings), b.geom)
      and ST_Intersects(ST_PointOnSurface(b.geom), a.geom_morocco_buildings)
    order by (ST_Area(ST_Intersection(a.geom_morocco_buildings, b.geom)) /
              ST_Area(ST_Union(a.geom_morocco_buildings, b.geom))) desc
    limit 1
);

-- append the geometries not referenced by other side
insert into morocco_buildings_iou_feature (geom_phase2, building_height_phase2)
select geom, building_height
from morocco_buildings_benchmark_phase2
where geom not in ( select geom_phase2 from morocco_buildings_iou_feature where geom_phase2 is not null );

-- zero out NULLs on phase1 side
update morocco_buildings_iou_feature
set geom_phase2 = 'SRID=3857; POLYGON EMPTY'
where geom_phase2 is null;
update morocco_buildings_iou_feature
set building_height_phase2 = 0
where building_height_phase2 is null;

-- zero out NULLs on testing set side
update morocco_buildings_iou_feature
set geom_morocco_buildings = 'SRID=3857; POLYGON EMPTY'
where geom_morocco_buildings is null;
update morocco_buildings_iou_feature
set building_height_morocco_buildings = 0
where building_height_morocco_buildings is null;

delete from morocco_buildings_iou_feature where ST_IsEmpty(geom_phase2) and ST_IsEmpty(geom_morocco_buildings);

-- calculate average IoU metrics of every buildings: 0.286
select a.city, avg(ST_Area(ST_Intersection(geom_morocco_buildings, geom_phase2)) /
           ST_Area(ST_Union(geom_morocco_buildings, geom_phase2)))
from morocco_buildings_iou_feature m
join morocco_buildings_benchmark_aoi a
    on ST_Intersects(coalesce(geom_morocco_buildings, geom_phase2), geom)
group by 1;
