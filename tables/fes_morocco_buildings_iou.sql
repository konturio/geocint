-- remove constraint from geometry column
alter table fes
    alter column wkb_geometry type geometry;

drop table if exists fes_aoi;
create table fes_aoi as (select ST_Convexhull(ST_Collect(wkb_geometry)) as geom
                         from fes);

-- add column to find buildings footprint
alter table fes
    add column footprint geometry;

update fes
set footprint = wkb_geometry;

-- create table with Fes buildings from neural network dataset (1st stage)
drop table if exists fes_phase1;
create table fes_phase1 as (
    select *
    from morocco_buildings_valid
    where ST_Intersects(geom, ((select geom from fes_aoi)))
);

-- update table with the same SRIDs
update fes
set wkb_geometry = ST_Transform(wkb_geometry, 3857);

update fes_aoi
set geom = ST_Transform(geom, 3857);

update fes_phase1
set geom = ST_Transform(geom, 3857);

-- find building corresponding to the manual selected buildings in Fes (manual)
update fes_phase1
set geom = ST_Intersection(geom, (select geom from fes_aoi));

-- first IoU metrics without translation calculations: 0.59
select ST_Area(
               ST_Intersection(
                           (select ST_Union(footprint) from fes),
                           (select ST_Union(geom) from fes_phase1)
                   )
           ) / ST_Area(
               ST_Union(
                           (select ST_Union(footprint) from fes),
                           (select ST_Union(geom) from fes_phase1)
                   )
           );

-- union and group by building_height manual selected buildings
drop table if exists fes_union;
create table fes_union as (
    select (ST_Dump(ST_Union(wkb_geometry))).geom as geom, building_height
    from fes
    group by building_height
);

-- union and group by building_height 1st stage selected buildings
drop table if exists fes_phase1_union;
create table fes_phase1_union as (
    select (ST_Dump(
            ST_Union(geom))).geom as geom,
           building_height
    from fes_phase1
    group by building_height
);

alter table fes_union
    add column phase_1 geometry;

-- add geometry from 1st stage intersected with manual data
update fes_union a
set phase_1 = (select ST_Union(geom) from fes_phase1 b where ST_Intersects(a.geom, ST_Pointonsurface(b.geom)));

-- calculations of X and Y shifts
select percentile_cont(0.5)
       within group (order by (building_height / ST_Distance(ST_Centroid(geom), ST_Centroid(phase_1)))),
       percentile_cont(0.5) within group (order by (ST_Distance(ST_Centroid(geom), ST_Centroid(phase_1)))),
       percentile_cont(0.5) within group (order by (building_height /
                                                    (ST_X(ST_Centroid(geom)) - ST_X(ST_Centroid(phase_1))))) as X,
       percentile_cont(0.5) within group (order by (building_height /
                                                    (ST_Y(ST_Centroid(geom)) - ST_Y(ST_Centroid(phase_1))))) as Y
from fes_union b;

-- update geometry with X and Y corrections
update fes
set footprint = ST_Translate(wkb_geometry, building_height / -4.34, building_height / 1.98);

-- second calculations of IoU metrics with translation corrections: 0.63
select ST_Area(
               ST_Intersection(
                           (select ST_Union(footprint) from fes),
                           (select ST_Union(geom) from fes_phase1)
                   )
           ) / ST_Area(
               ST_Union(
                           (select ST_Union(footprint) from fes),
                           (select ST_Union(geom) from fes_phase1)
                   )
           );

-- 3D
-- create indexes for geometry in tables
create index on fes using gist (wkb_geometry);
create index on fes_phase1 using gist (geom);

-- create table with union manual and 1st stage building polygons
drop table if exists fes_polygons;
create table fes_polygons as (select wkb_geometry as geom
                              from fes
                              union all
                              select geom
                              from fes_phase1);

-- create table with all dropped polygon parts of union buildings dataset
drop table if exists fes_iou_linework;
create table fes_iou_linework as
with fes_edges as (
    select (ST_Dump(ST_UnaryUnion(ST_Collect(ST_Boundary(geom))))).geom
    from fes_polygons
),
     fes_parts as (
         select (ST_Dump(ST_Polygonize(geom))).geom
         from fes_edges
     ),
     fes_parts_count as (
         select fes_parts.geom, count(*)
         from fes_parts
                  join fes_polygons p
                       on ST_Intersects(p.geom, ST_PointOnSurface(fes_parts.geom))
         group by fes_parts.geom
     )
select *
from fes_parts;

-- add columns with min and max building height values
alter table fes_iou_linework
    add column min_height float;
alter table fes_iou_linework
    add column max_height float;

-- update null values into columns to zero values
update fes_iou_linework
set min_height = 0,
    max_height = 0;

-- set min and max building height to the dropped building polygons from 1st stage dataset
update fes_iou_linework a
set min_height = (select max(building_height) from fes_phase1 b where ST_Intersects(ST_PointOnSurface(a.geom), b.geom));
update fes_iou_linework a
set max_height = (select max(building_height)
                  from fes b
                  where ST_Intersects(ST_PointOnSurface(a.geom), b.wkb_geometry));

-- update null values into min anf max building height columns to zero values

update fes_iou_linework
set min_height = 0
where min_height is null;
update fes_iou_linework
set max_height = 0
where max_height is null;

-- update min and max building height values on ascending order
update fes_iou_linework
set min_height = least(min_height, max_height),
    max_height = greatest(max_height, min_height);

-- calculate IoU metrics for all 3D buildings in Fes: 0.38
select sum(min_height * ST_Area(geom)) as intersection,
       sum(max_height * ST_Area(geom)),
       sum(min_height * ST_Area(geom)) / sum(max_height * ST_Area(geom))
from fes_iou_linework;

-- calculate IoU metrics for every building in Fes
-- сreate table with corresponding geometries of buildings from union manual and 1st stage datasets
drop table if exists fes_iou_feature;
create table fes_iou_feature as (
    select wkb_geometry    as geom_fes,
           building_height as building_height_fes,
           null::geometry  as geom_phase1,
           null::float     as building_height_phase1
    from fes
);

-- update 1st stage geometry values
update fes_iou_feature a
set geom_phase1 = (select geom
                   from fes_phase1 b
                   where ST_Intersects(ST_PointOnSurface(a.geom_fes), b.geom)
                     and ST_Intersects(ST_PointOnSurface(b.geom), a.geom_fes));

-- update 1st stage building_height values
update fes_iou_feature a
set building_height_phase1 = (select building_height
                              from fes_phase1 b
                              where ST_Intersects(ST_PointOnSurface(a.geom_fes), b.geom)
                                and ST_Intersects(ST_PointOnSurface(b.geom), a.geom_fes));

-- insert geometry and building_height values into fes_iou_feature table
insert into fes_iou_feature (geom_phase1, building_height_phase1)
select geom, building_height
from fes_phase1
where geom not in (select geom_phase1 from fes_iou_feature);

-- update null 1st stage's geometry values in fes_iou_feature table
update fes_iou_feature
set geom_phase1 = 'SRID=3857; POLYGON EMPTY'
where geom_phase1 is null;

-- update null 1st stage's building_height values in fes_iou_feature table to zero values
update fes_iou_feature
set building_height_phase1 = 0
where building_height_phase1 is null;

-- update null manual's geometry values in fes_iou_feature table
update fes_iou_feature
set geom_fes = 'SRID=3857; POLYGON EMPTY'
where geom_fes is null;

-- update null manual's building_height values in fes_iou_feature table to zero values
update fes_iou_feature
set building_height_fes = 0
where building_height_fes is null;

-- calculate average IoU metrics of every buildings: 0.22
select avg(ST_Area(ST_Intersection(geom_fes, geom_phase1)) / ST_Area(ST_Union(geom_fes, geom_phase1)))
from fes_iou_feature;
