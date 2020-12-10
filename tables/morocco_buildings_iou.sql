-- Calculation IoU metrics for all buildings from test benchmark

-- Step 1. Import data and reformat it.

-- Import the JSON files:
-- ogr2ogr PG:"" morocco_buildings_manual.geojson
-- ogr2ogr PG:"" morocco_buildings_benchmark_aoi.geojson
drop table if exists phase_metrics;
create table phase_metrics
(
    City   text,
    Metric text,
    Value  float
);

alter table morocco_buildings_extents
    rename column wkb_geometry to geom;
update morocco_buildings_extents
set geom = ST_Transform(geom, 3857);

alter table morocco_buildings_manual_roofprints
    rename column wkb_geometry to geom;
alter table morocco_buildings_manual_roofprints
    alter column geom type geometry;
update morocco_buildings_manual_roofprints
set geom = ST_Transform(geom, 3857);

alter table morocco_buildings_manual
    rename column wkb_geometry to footprint;
alter table morocco_buildings_manual
    alter column footprint type geometry;
update morocco_buildings_manual
set footprint = ST_Transform(footprint, 3857);

drop table if exists morocco_buildings_manual_extent;
create table morocco_buildings_manual_extent as (
    select is_confident,
           building_height,
           ST_Intersection(ST_MakeValid(b.footprint), a.geom) as footprint,
           a.city
    from morocco_buildings_manual b
             join morocco_buildings_extents a
                  on ST_Intersects(b.footprint, ST_MakeValid(a.geom))
);

drop table if exists morocco_buildings_benchmark_phase2;
create table morocco_buildings_benchmark_phase2 as (
    select building_height                                     as building_height,
           ST_Intersection(ST_Transform(b.geom, 3857), a.geom) as geom,
           a.city
    from :morocco_buildings_benchmark b
             join morocco_buildings_extents a
                  on ST_Intersects(b.geom, ST_Transform(a.geom, 4326))
);

-- round the coordinates a little bit to make intersection/union more robust
update morocco_buildings_manual_extent
set footprint = ST_CollectionExtract(
        ST_MakeValid(ST_Segmentize(ST_SnapToGrid(ST_Transform(ST_Simplify(footprint, 0), 3857), 0.031415926), 5)), 3);
update morocco_buildings_benchmark_phase2
set geom = ST_CollectionExtract(
        ST_MakeValid(ST_Segmentize(ST_SnapToGrid(ST_Transform(ST_Simplify(geom, 0), 3857), 0.031415926), 5)), 3);


-- Step 2. Generate min / max heights map on the pieces of input geometry
-- collect both sets into one table
drop table if exists morocco_buildings_polygons_ph2;
create table morocco_buildings_polygons_ph2 as (
    select city, footprint as geom
    from morocco_buildings_manual_extent
    union all
    select city, geom
    from morocco_buildings_benchmark_phase2
);

delete
from morocco_buildings_polygons_ph2
where ST_Dimension(ST_Boundary(geom)) is null;

delete
from morocco_buildings_polygons_ph2
where ST_Dimension(ST_Boundary(geom)) = 2;

-- generate the breakout table with polygons of all candidate pieces
drop table if exists morocco_buildings_linework_ph2;
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

create index on morocco_buildings_benchmark_phase2 using gist (geom);
create index on morocco_buildings_manual_extent using gist (footprint);
create index on morocco_buildings_linework_ph2 using gist (geom);

-- for each piece, get heights from both datasets. will swap them later.
set enable_seqscan to off;
update morocco_buildings_linework_ph2 a
set min_height = (
    select max(building_height)
    from morocco_buildings_benchmark_phase2 b
    where ST_Intersects(ST_PointOnSurface(a.geom), b.geom)
      and a.geom && b.geom
);

update morocco_buildings_linework_ph2 a
set max_height = (
    select max(building_height)
    from morocco_buildings_manual_extent b
    where ST_Intersects(ST_PointOnSurface(a.geom), b.footprint)
      and a.geom && b.footprint
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

delete
from morocco_buildings_linework_ph2
where min_height = 0
  and max_height = 0;

insert into phase_metrics (city, metric, value)
select city, 'Phase 2 detected polygons', count(*)
from morocco_buildings_benchmark_phase2
group by city;

-- Step 3. Calculate IoU in 2D and 3D
-- calculate 2D IoU metrics
insert into phase_metrics (city, metric, value)
select b.city, '2D_IoU', sum(ST_Area(a.geom)) filter (where min_height > 0) / sum(ST_Area(a.geom))
from morocco_buildings_linework_ph2 a
         join morocco_buildings_extents b
              on ST_Intersects(a.geom, b.geom)
group by b.city;

-- calculate 3D IoU metrics
insert into phase_metrics (city, metric, value)
select b.city, '3D_IoU', sum(min_height * ST_Area(a.geom)) / sum(max_height * ST_Area(a.geom))
from morocco_buildings_linework_ph2 a
         join morocco_buildings_extents b
              on ST_Intersects(a.geom, b.geom)
group by b.city;

-- Step 4. Generate feature-to-feature IoU.
-- table for the matching geometries
drop table if exists morocco_buildings_iou_feature;
create table morocco_buildings_iou_feature as (
    select distinct footprint       as geom_morocco_buildings,
                    building_height as building_height_morocco_buildings,
                    null::geometry  as geom_phase2,
                    null::float     as building_height_phase2,
                    is_confident
    from morocco_buildings_manual_extent
);

create index on morocco_buildings_iou_feature using gist (geom_phase2);
create index on morocco_buildings_iou_feature using gist (geom_morocco_buildings);
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
where geom not in (select geom_phase2 from morocco_buildings_iou_feature where geom_phase2 is not null);

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

delete
from morocco_buildings_iou_feature
where ST_IsEmpty(geom_phase2)
  and ST_IsEmpty(geom_morocco_buildings);

-- calculate average IoU metrics of every buildings
insert into phase_metrics (city, metric, value)
select a.city,
       'Per-segment_IoU',
       avg(ST_Area(ST_Intersection(geom_morocco_buildings, geom_phase2)) /
           ST_Area(ST_Union(geom_morocco_buildings, geom_phase2)))
from morocco_buildings_iou_feature m
         join morocco_buildings_extents a
              on ST_Intersects(coalesce(geom_morocco_buildings, geom_phase2), geom)
group by 1;

insert into phase_metrics (city, metric, value)
select a.city,
       'Per-segment_IoU_not_matched',
       avg(ST_Area(ST_Intersection(geom_morocco_buildings, geom_phase2)) /
           ST_Area(ST_Union(geom_morocco_buildings, geom_phase2)))
from morocco_buildings_iou_feature m
         join morocco_buildings_extents a
              on ST_Intersects(coalesce(geom_morocco_buildings, geom_phase2), geom)
where not ST_isEmpty(geom_morocco_buildings)
  and not ST_isEmpty(geom_phase2)
group by 1;

-- Step 5. Height metrics
-- calculate HRMSD in meters
insert into phase_metrics (city, metric, value)
select city, 'Height_RMSD', sqrt(avg(power(building_height_phase2 - building_height_morocco_buildings, 2)))
from morocco_buildings_iou_feature a
         join morocco_buildings_extents b on ST_Intersects(coalesce(geom_morocco_buildings, geom_phase2), geom)
where building_height_phase2 > 0
  and building_height_morocco_buildings > 0
group by 1;

-- calculate HRMSD in metres where is_confident = true
insert into phase_metrics (city, metric, value)
select city,
       'Height_RMSD_verified',
       sqrt(avg(power(building_height_phase2 - building_height_morocco_buildings, 2)))
from morocco_buildings_iou_feature a
         join morocco_buildings_extents b on ST_Intersects(coalesce(geom_morocco_buildings, geom_phase2), geom)
where building_height_phase2 > 0
  and building_height_morocco_buildings > 0
  and is_confident is true
group by 1;


-- Step 6. IoU roofprints
-- ST_MakeValid for geometry manual split roofprints
drop table if exists morocco_buildings_manual_roofprints_extent;
create table morocco_buildings_manual_roofprints_extent as (
    select is_confident,
           building_height,
           ST_Intersection(ST_MakeValid(b.geom), a.geom) as geom,
           a.city
    from morocco_buildings_manual_roofprints b
             join morocco_buildings_extents a
                  on ST_Intersects(ST_MakeValid(b.geom), a.geom)
);

drop table if exists morocco_buildings_benchmark_roofprints_union;
create table morocco_buildings_benchmark_roofprints_union as (
    select (ST_Dump(ST_Union(geom))).geom as geom,
           building_height,
           city
    from morocco_buildings_benchmark_roofprints_extents
    group by building_height, city
);

-- IoU Geoalert's roofprints vs. benchmark's roofprints
drop table if exists morocco_buildings_manual_roofprints_extent_union;
create table morocco_buildings_manual_roofprints_extent_union as (
    select (ST_Dump(ST_Union(ST_MakeValid(
            ST_Segmentize(ST_SnapToGrid(ST_Transform(ST_Simplify(geom, 0), 3857), 0.031415926), 5))))).geom as geom,
           building_height,
           city
    from morocco_buildings_manual_roofprints_extent
    group by building_height, city
);

update morocco_buildings_manual_roofprints_extent_union a
set geom = ST_Intersection(a.geom, (
    select geom
    from morocco_buildings_extents b
    where a.city = b.city)
    );

insert into phase_metrics (city, metric, value)
select ref_city,'2D_IoU_roofprints',
       ST_Area(ST_Intersection(
               (select ST_Union(ST_MakeValid(geom))
                from morocco_buildings_benchmark_roofprints_union
                where city = ref_city),
               (select ST_Union(ST_MakeValid(geom))
                from morocco_buildings_manual_roofprints_extent_union
                where city = ref_city))) /
       ST_Area(ST_Union(
               (select ST_Union(ST_MakeValid(geom))
                from morocco_buildings_benchmark_roofprints_union
                where city = ref_city),
               (select ST_Union(ST_MakeValid(geom))
                from morocco_buildings_manual_roofprints_extent_union
                where city = ref_city)))
from (
         select distinct city as ref_city
         from morocco_buildings_manual_roofprints_extent_union
     ) z;

drop table if exists morocco_buildings_extents;
drop table if exists morocco_buildings_manual;
drop table if exists morocco_buildings_manual_roofprints;
drop table if exists morocco_buildings_manual_roofprints_extent_union;
drop table if exists morocco_buildings_benchmark_phase2;
drop table if exists morocco_buildings_iou_feature;
drop table if exists morocco_buildings_linework_ph2;
drop table if exists morocco_buildings_polygons_ph2;
drop table if exists morocco_buildings_benchmark_roofprints_union;
