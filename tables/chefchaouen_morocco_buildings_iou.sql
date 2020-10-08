-- remove constraint from geometry column
alter table chefchaouen
    alter column wkb_geometry type geometry;

drop table if exists chefchaouen_aoi;
create table chefchaouen_aoi as (select ST_Convexhull(ST_Collect(wkb_geometry)) as geom
                                 from chefchaouen);

-- create table with Fes buildings from neural network dataset (1st stage)
drop table if exists chefchaouen_phase1;
create table chefchaouen_phase1 as (
    select *
    from morocco_buildings
    where ST_Intersects(geom, (select geom from chefchaouen_aoi))
);

-- update table with the same SRIDs
update chefchaouen
set wkb_geometry = ST_Transform(wkb_geometry, 3857);

update chefchaouen_aoi
set geom = ST_Transform(geom, 3857);

update chefchaouen_phase1
set geom = ST_Transform(geom, 3857);

-- find building corresponding to the manual selected buildings in Сhefchaouen (manual)
update chefchaouen_phase1
set geom = ST_Intersection(geom, (select geom from chefchaouen_aoi));

-- add column to find buildings footprint

alter table chefchaouen
    add column footprint geometry;

update chefchaouen
set footprint = wkb_geometry;

-- first IoU metrics without translation calculations: 0.64

select ST_Area(
               ST_Intersection(
                           (select ST_Union(footprint) from chefchaouen),
                           (select ST_Union(geom) from chefchaouen_phase1)
                   )
           ) / ST_Area(
               ST_Union(
                           (select ST_Union(footprint) from chefchaouen),
                           (select ST_Union(geom) from chefchaouen_phase1)
                   )
           );

-- union and group by building_height manual selected buildings

drop table if exists chefchaouen_union;
create table chefchaouen_union as (
    select (ST_Dump(ST_Union(wkb_geometry))).geom as geom, building_height
    from chefchaouen
    group by building_height
);

-- union and group by building_height 1st stage selected buildings

drop table if exists chefchaouen_phase1_union;
create table chefchaouen_phase1_union as (
    select (ST_Dump(
            ST_Union(geom))).geom as geom,
           building_height
    from chefchaouen_phase1
    group by building_height
);

alter table chefchaouen_union
    add column phase_1 geometry;

-- add geometry from 1st stage intersected with manual data

update chefchaouen_union a
set phase_1 = (select ST_Union(geom) from chefchaouen_phase1 b where ST_Intersects(a.geom, ST_Pointonsurface(b.geom)));

-- calculations of X and Y shifts

select percentile_cont(0.5)
       within group (order by (building_height / ST_Distance(ST_Centroid(geom), ST_Centroid(phase_1)))),
       percentile_cont(0.5) within group (order by (ST_Distance(ST_Centroid(geom), ST_Centroid(phase_1)))),
       percentile_cont(0.5) within group (order by (building_height /
                                                    (ST_X(ST_Centroid(geom)) - ST_X(ST_Centroid(phase_1))))) as X,
       percentile_cont(0.5) within group (order by (building_height /
                                                    (ST_Y(ST_Centroid(geom)) - ST_Y(ST_Centroid(phase_1))))) as Y
from chefchaouen_union b;

-- update geometry with X and Y corrections

update chefchaouen
set footprint = ST_Translate(wkb_geometry, building_height / -1.83, building_height / 2.79);

-- second calculations of IoU metrics with translation corrections: 0.74

select ST_Area(
               ST_Intersection(
                           (select ST_Union(footprint) from chefchaouen),
                           (select ST_Union(geom) from chefchaouen_phase1)
                   )
           ) / ST_Area(
               ST_Union(
                           (select ST_Union(footprint) from chefchaouen),
                           (select ST_Union(geom) from chefchaouen_phase1)
                   )
           );

-- 3D
-- create indexes for geometry in tables

create index on chefchaouen using gist (wkb_geometry);
create index on chefchaouen_phase1 using gist (geom);

-- create table with union manual and 1st stage building polygons

drop table if exists chefchaouen_polygons;
create table chefchaouen_polygons as (select wkb_geometry as geom
                              from chefchaouen
                              union all
                              select geom
                              from chefchaouen_phase1);

-- create table with all dropped polygon parts of union buildings dataset

drop table if exists chefchaouen_iou_linework;
create table chefchaouen_iou_linework as
with chefchaouen_edges as (
    select (ST_Dump(ST_UnaryUnion(ST_Collect(ST_Boundary(geom))))).geom
    from chefchaouen_polygons
),
     chefchaouen_parts as (
         select (ST_Dump(ST_Polygonize(geom))).geom
         from chefchaouen_edges
     ),
     fes_parts_count as (
         select chefchaouen_parts.geom, count(*)
         from chefchaouen_parts
                  join fes_polygons p
                       on ST_Intersects(p.geom, ST_PointOnSurface(chefchaouen_parts.geom))
         group by chefchaouen_parts.geom
     )
select *
from chefchaouen_parts;

-- add columns with min and max building height values

alter table chefchaouen_iou_linework
    add column min_height float;
alter table chefchaouen_iou_linework
    add column max_height float;

-- update null values into columns to zero values

update chefchaouen_iou_linework
set min_height = 0,
    max_height = 0;

-- set min and max building height to the dropped building polygons from 1st stage dataset

update chefchaouen_iou_linework a
set min_height = (select max(building_height) from chefchaouen_phase1 b where ST_Intersects(ST_PointOnSurface(a.geom), b.geom));

update chefchaouen_iou_linework a
set max_height = (select max(building_height)
                  from chefchaouen b
                  where ST_Intersects(ST_PointOnSurface(a.geom), b.wkb_geometry));

-- update null values into min anf max building height columns to zero values

update chefchaouen_iou_linework
set min_height = 0
where min_height is null;
update chefchaouen_iou_linework
set max_height = 0
where max_height is null;

-- update min and max building height values on ascending order

update chefchaouen_iou_linework
set min_height = least(min_height, max_height),
    max_height = greatest(max_height, min_height);

-- calculate IoU metrics for all 3D buildings in Fes: 0.48

select sum(min_height * ST_Area(geom)) as intersection,
       sum(max_height * ST_Area(geom)),
       sum(min_height * ST_Area(geom)) / sum(max_height * ST_Area(geom))
from chefchaouen_iou_linework;

-- calculate IoU metrics for every building in Сhefchaouen

-- сreate table with corresponding geometries of buildings from union manual and 1st stage datasets

drop table if exists chefchaouen_iou_feature;
create table chefchaouen_iou_feature as (
    select wkb_geometry    as geom_chefchaouen,
           building_height as building_height_chefchaouen,
           null::geometry  as geom_phase1,
           null::float     as building_height_phase1
    from chefchaouen
);

-- update 1st stage geometry values

update chefchaouen_iou_feature a
set geom_phase1 = (select geom
                   from chefchaouen_phase1 b
                   where ST_Intersects(ST_PointOnSurface(a.geom_chefchaouen), b.geom)
                     and ST_Intersects(ST_PointOnSurface(b.geom), a.geom_chefchaouen));

-- update 1st stage building_height values

update chefchaouen_iou_feature a
set building_height_phase1 = (select building_height
                              from chefchaouen_phase1 b
                              where ST_Intersects(ST_PointOnSurface(a.geom_chefchaouen), b.geom)
                                and ST_Intersects(ST_PointOnSurface(b.geom), a.geom_chefchaouen));

-- insert geometry and building_height values into chefchaouen_iou_feature table

insert into chefchaouen_iou_feature (geom_phase1, building_height_phase1)
select geom, building_height
from chefchaouen_phase1
where geom not in (select geom_phase1 from chefchaouen_iou_feature);

-- update null 1st stage's geometry values in chefchaouen_iou_feature table

update chefchaouen_iou_feature
set geom_phase1 = 'SRID=3857; POLYGON EMPTY'
where geom_phase1 is null;

-- update null 1st stage's building_height values in chefchaouen_iou_feature table to zero values

update chefchaouen_iou_feature
set building_height_phase1 = 0
where building_height_phase1 is null;

-- update null manual's geometry values in chefchaouen_iou_feature table

update chefchaouen_iou_feature
set geom_chefchaouen = 'SRID=3857; POLYGON EMPTY'
where geom_chefchaouen is null;

-- update null manual's building_height values in chefchaouen_iou_feature table to zero values

update chefchaouen_iou_feature
    set building_height_chefchaouen = 0
where building_height_chefchaouen is null;

-- calculate average IoU metrics of every buildings: 0.22

select avg(ST_Area(ST_Intersection(geom_chefchaouen, geom_phase1)) / ST_Area(ST_Union(geom_chefchaouen, geom_phase1)))
from chefchaouen_iou_feature;
