-- remove constraint from geometry column
alter table agadir
    alter column wkb_geometry type geometry;

drop table if exists agadir_aoi;
create table agadir_aoi as (select ST_Convexhull(ST_Collect(wkb_geometry)) as geom
                            from agadir);

-- create table with Agadir buildings from neural network dataset (1st stage)
drop table if exists agadir_phase1;
create table agadir_phase1 as (
    select *
    from morocco_buildings_valid
    where ST_Intersects(geom, (select geom from agadir_aoi))
);

-- update table with the same SRIDs
update agadir
set wkb_geometry = ST_Transform(wkb_geometry, 3857);

update agadir_aoi
set geom = ST_Transform(geom, 3857);
update agadir_phase1
set geom = ST_Transform(geom, 3857);

-- find building corresponding to the manual selected buildings in Agadir (manual)
update agadir_phase1
set geom = ST_Intersection(geom, (select geom from agadir_aoi));

-- add column to find buildings footprint
alter table agadir
    add column footprint geometry;

update agadir
set footprint = wkb_geometry;

-- first IoU metrics without correction calculations: 0.53
select ST_Area(
               ST_Intersection(
                           (select ST_Union(footprint) from agadir),
                           (select ST_Union(geom) from agadir_phase1)
                   )
           ) / ST_Area(
               ST_Union(
                           (select ST_Union(footprint) from agadir),
                           (select ST_Union(geom) from agadir_phase1)
                   )
           );

-- union and group by building_height manual selected buildings
drop table if exists agadir_union;
create table agadir_union as (
    select (ST_Dump(ST_Union(wkb_geometry))).geom as geom, building_height
    from agadir
    group by building_height
);

-- union and group by building_height 1st stage selected buildings
drop table if exists agadir_phase1_union;
create table agadir_phase1_union as (
    select (ST_Dump(
            ST_Union(geom))).geom as geom,
           building_height
    from agadir_phase1
    group by building_height
);

alter table agadir_union
    add column phase_1 geometry;

-- add geometry from 1st stage intersected with manual data
update agadir_union a
set phase_1 = (select ST_Union(geom) from agadir_phase1 b where ST_Intersects(a.geom, ST_PointOnSurface(b.geom)));

-- calculations of X and Y shifts
select percentile_cont(0.5)
       within group (order by (building_height / ST_Distance(ST_Centroid(geom), ST_Centroid(phase_1)))),
       percentile_cont(0.5) within group (order by (ST_Distance(ST_Centroid(geom), ST_Centroid(phase_1)))),
       percentile_cont(0.5) within group (order by (building_height /
                                                    (ST_X(ST_Centroid(geom)) - ST_X(ST_Centroid(phase_1))))) as X,
       percentile_cont(0.5) within group (order by (building_height /
                                                    (ST_Y(ST_Centroid(geom)) - ST_Y(ST_Centroid(phase_1))))) as Y
from agadir_union b;

-- update geometry with X and Y corrections
update agadir
set footprint = ST_Translate(wkb_geometry, building_height / -2.16, building_height / 1.81);

-- second calculations of IoU metrics with translation corrections: 0.74
select ST_Area(
               ST_Intersection(
                           (select ST_Union(footprint) from agadir),
                           (select ST_Union(geom) from agadir_phase1)
                   )
           ) / ST_Area(
               ST_Union(
                           (select ST_Union(footprint) from agadir),
                           (select ST_Union(geom) from agadir_phase1)
                   )
           );

-- 3D
-- create indexes for geometry in tables
create index on agadir using gist (wkb_geometry);
create index on agadir_phase1 using gist (geom);

-- create table with union manual and 1st stage building polygons
drop table if exists agadir_polygons;
create table agadir_polygons as (select wkb_geometry as geom
                                 from agadir
                                 union all
                                 select geom
                                 from agadir_phase1);

-- create table with all dropped polygon parts of union buildings dataset: 0.51
drop table if exists agadir_iou_linework;
create table agadir_iou_linework as
with agadir_edges as (
    select (ST_Dump(ST_UnaryUnion(ST_Collect(ST_Boundary(geom))))).geom
    from agadir_polygons
),
     agadir_parts as (
         select (ST_Dump(ST_Polygonize(geom))).geom
         from agadir_edges
     ),
     agadir_parts_count as (
         select agadir_parts.geom, count(*)
         from agadir_parts
                  join agadir_polygons p
                       on ST_Intersects(p.geom, ST_Pointonsurface(agadir_parts.geom))
         group by agadir_parts.geom
     )
select *
from agadir_parts;

-- add columns with min and max building height values
alter table agadir_iou_linework
    add column min_height float;
alter table agadir_iou_linework
    add column max_height float;

-- update null values into columns to zero values
update agadir_iou_linework
set min_height = 0,
    max_height = 0;

-- set min and max building height to the dropped building polygons from 1st stage dataset
update agadir_iou_linework a
set min_height = (select max(building_height)
                  from agadir_phase1 b
                  where ST_Intersects(ST_PointOnSurface(a.geom), b.geom));
update agadir_iou_linework a
set max_height = (select max(building_height)
                  from agadir b
                  where ST_Intersects(ST_PointOnSurface(a.geom), b.wkb_geometry));

-- update null values into min anf max building height columns to zero values
update agadir_iou_linework
set min_height = 0
where min_height is null;
update agadir_iou_linework
set max_height = 0
where max_height is null;

-- update min and max building height values on ascending order
update agadir_iou_linework
set min_height = least(min_height, max_height),
    max_height = greatest(max_height, min_height);

-- calculate IoU metrics for all 3D buildings in Agadir: 0.43
select sum(min_height * ST_Area(geom)) as intersection,
       sum(max_height * ST_Area(geom)),
       sum(min_height * ST_Area(geom)) / sum(max_height * ST_Area(geom))
from agadir_iou_linework;

-- calculate IoU metrics for every building in Agadir

-- сreate table with corresponding geometries of buildings from union manual and 1st stage datasets

drop table if exists agadir_iou_feature;
create table agadir_iou_feature as (
    select wkb_geometry    as geom_agadir,
           building_height as building_height_agadir,
           null::geometry  as geom_phase1,
           null::float     as building_height_phase1
    from agadir
);

-- update 1st stage geometry values
update agadir_iou_feature a
set geom_phase1 = (select geom
                   from agadir_phase1 b
                   where ST_Intersects(ST_PointOnSurface(a.geom_agadir), b.geom)
                     and ST_Intersects(ST_PointOnSurface(b.geom), a.geom_agadir)
                   order by (ST_Area(ST_Intersection(geom_agadir, geom)) / ST_Area(ST_Union(geom_agadir, geom))) desc
                   limit 1);

-- update 1st stage building_height values
update agadir_iou_feature a
set building_height_phase1 = (select building_height
                              from fes_phase1 b
                              where ST_Intersects(ST_Pointonsurface(a.geom_agadir), b.geom)
                                and ST_Intersects(ST_Pointonsurface(b.geom), a.geom_agadir)
                              order by (ST_Area(ST_Intersection(geom_agadir, geom)) /
                                        ST_Area(ST_Union(geom_agadir, geom))) desc
                              limit 1);

-- insert geometry and building_height values into agadir_iou_feature table
insert into agadir_iou_feature (geom_phase1, building_height_phase1)
select geom, building_height
from agadir_phase1
where geom not in (select geom_phase1 from agadir_iou_feature);

-- update null 1st stage's geometry values in agadir_iou_feature table
update agadir_iou_feature
set geom_phase1 = 'SRID=3857; POLYGON EMPTY'
where geom_phase1 is null;

-- update null 1st stage's building_height values in agadir_iou_feature table to zero values
update agadir_iou_feature
set building_height_phase1 = 0
where building_height_phase1 is null;

-- update null manual's geometry values in agadir_iou_feature table
update agadir_iou_feature
set geom_agadir = 'SRID=3857; POLYGON EMPTY'
where geom_agadir is null;

-- update null manual's building_height values in agadir_iou_feature table to zero values
update agadir_iou_feature
set building_height_agadir = 0
where building_height_agadir is null;

-- calculate average IoU metrics of every buildings: 0.18
select avg(ST_Area(ST_Intersection(geom_agadir, geom_phase1)) / ST_Area(ST_Union(geom_agadir, geom_phase1)))
from agadir_iou_feature;
