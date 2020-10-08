-- remove constraints and tweak names
alter table morocco_buildings_manual
    alter column wkb_geometry type geometry;
alter table morocco_buildings_manual
    rename column wkb_geometry to footprint;

-- reproject and limit precision to stabilize the calculation
update morocco_buildings_manual
set footprint = ST_CollectionExtract(ST_MakeValid(ST_SnapToGrid(ST_Transform(footprint, 3857), 0.01)), 3);

-- remove constraints and tweak names
alter table morocco_buildings_aoi
    alter column wkb_geometry type geometry;
alter table morocco_buildings_aoi
    rename column wkb_geometry to geom;

-- reproject
update morocco_buildings_aoi
set geom = ST_Transform(geom, 3857);

-- collect geometries to be validated
drop table if exists morocco_buildings_phase1;
create table morocco_buildings_phase1 as (
    select *
    from morocco_buildings
    where ST_Intersects(ST_Transform(geom, 3857), ( select geom from morocco_buildings_aoi )) );

-- reproject and limit precision to stabilize the calculation
update morocco_buildings_phase1
set geom = ST_CollectionExtract(ST_MakeValid(ST_SnapToGrid(ST_Transform(geom, 3857), 0.01)), 3);

-- clip the geometries to boundary of validation dataset
update morocco_buildings_phase1
set geom = ST_Intersection(geom, ( select geom from morocco_buildings_aoi ));

-- index the data
create index on morocco_buildings_manual using gist (footprint);
create index on morocco_buildings_phase1 using gist (geom);

-- Step 2. Generate min / max heights map on the pieces of input geometry

-- collect both sets into one table
drop table if exists morocco_buildings_polygons;
create table morocco_buildings_polygons as (
    select footprint as geom
    from morocco_buildings_manual
    union all
    select geom
    from morocco_buildings_phase1
);

-- generate the breakout table with polygons of all candidate pieces
drop table if exists morocco_buildings_linework;
create table morocco_buildings_linework as
with morocco_buildings_edges as (
    select (ST_Dump(ST_UnaryUnion(ST_Collect(ST_Boundary(geom))))).geom
    from morocco_buildings_polygons
),
     morocco_buildings_parts as (
         select (ST_Dump(ST_Polygonize(geom))).geom
         from morocco_buildings_edges
     )
select *
from morocco_buildings_parts;

-- add columns with min and max building height values and zero them out
alter table morocco_buildings_linework
    add column min_height float;
alter table morocco_buildings_linework
    add column max_height float;
update morocco_buildings_linework
set min_height = 0,
    max_height = 0;

-- for each piece, get heights from both datasets. will swap them later.
update morocco_buildings_linework a
set min_height = (
    select max(building_height)
    from morocco_buildings_phase1 b
    where ST_Intersects(ST_PointOnSurface(a.geom), b.geom)
);

update morocco_buildings_linework a
set max_height = (
    select max(building_height)
    from morocco_buildings_manual b
    where ST_Intersects(ST_PointOnSurface(a.geom), b.footprint)
);

-- replace NULLs with 0's
update morocco_buildings_linework
set min_height = 0
where min_height is null;

update morocco_buildings_linework
set max_height = 0
where max_height is null;

-- swap min and max to be correct
update morocco_buildings_linework
set min_height = least(min_height, max_height),
    max_height = greatest(max_height, min_height);

-- Step 3. Calculate IoU in 2D and 3D

-- 2D IoU: 0.659
select sum(ST_Area(geom)) filter (where min_height > 0) / sum(ST_Area(geom)) as IoU
from morocco_buildings_linework;

-- calculate IoU metrics for all 3D buildings: 0.478
select sum(min_height * ST_Area(geom)) / sum(max_height * ST_Area(geom))
from morocco_buildings_linework;

-- Step 4. Generate feature-to-feature IoU.

-- table for the matching geometries
drop table if exists morocco_buildings_iou_feature;
create table morocco_buildings_iou_feature as (
    select footprint as geom_morocco_buildings,
           building_height as building_height_morocco_buildings,
           null::geometry as geom_phase1,
           null::float as building_height_phase1
    from morocco_buildings_manual
);

-- match geometries if representative point on one is insede other and vice versa.
-- in case of collision take option with better IoU.
update morocco_buildings_iou_feature a
set geom_phase1 = (
    select geom
    from morocco_buildings_phase1 b
    where ST_Intersects(ST_PointOnSurface(a.geom_morocco_buildings), b.geom)
      and ST_Intersects(ST_PointOnSurface(b.geom), a.geom_morocco_buildings)
    order by (ST_Area(ST_Intersection(a.geom_morocco_buildings, b.geom)) /
              ST_Area(ST_Union(a.geom_morocco_buildings, b.geom))) desc
    limit 1
);
update morocco_buildings_iou_feature a
set building_height_phase1 = (
    select building_height
    from morocco_buildings_phase1 b
    where ST_Intersects(ST_PointOnSurface(a.geom_morocco_buildings), b.geom)
      and ST_Intersects(ST_PointOnSurface(b.geom), a.geom_morocco_buildings)
    order by (ST_Area(ST_Intersection(a.geom_morocco_buildings, b.geom)) /
              ST_Area(ST_Union(a.geom_morocco_buildings, b.geom))) desc
    limit 1
);

-- append the geometries not referenced by other side
insert into morocco_buildings_iou_feature (geom_phase1, building_height_phase1)
select geom, building_height
from morocco_buildings_phase1
where geom not in ( select geom_phase1 from morocco_buildings_iou_feature );

-- zero out NULLs on phase1 side
update morocco_buildings_iou_feature
set geom_phase1 = 'SRID=3857; POLYGON EMPTY'
where geom_phase1 is null;
update morocco_buildings_iou_feature
set building_height_phase1 = 0
where building_height_phase1 is null;

-- zero out NULLs on testing set side
update morocco_buildings_iou_feature
set geom_morocco_buildings = 'SRID=3857; POLYGON EMPTY'
where geom_morocco_buildings is null;
update morocco_buildings_iou_feature
set building_height_morocco_buildings = 0
where building_height_morocco_buildings is null;

delete from morocco_buildings_iou_feature where ST_IsEmpty(geom_phase1) and ST_IsEmpty(geom_morocco_buildings);

-- calculate average IoU metrics of every buildings: 0.367
select avg(ST_Area(ST_Intersection(geom_morocco_buildings, geom_phase1)) /
           ST_Area(ST_Union(geom_morocco_buildings, geom_phase1)))
from morocco_buildings_iou_feature;
