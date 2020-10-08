-- remove constraint from geometry column
alter table casablanca
    alter column wkb_geometry type geometry;

update casablanca
set wkb_geometry = ST_Transform(wkb_geometry, 3857);

insert into casablanca (wkb_geometry, building_height)(
    with edges as (
        select (ST_Dump(ST_UnaryUnion(ST_Collect((wkb_geometry))))).geom
        from casablanca
        where ST_Dimension(wkb_geometry) = 1
    )
    select (ST_Dump(ST_Polygonize(geom))).geom,
           10 as building_height
    from edges
);

delete
from casablanca
where ST_Dimension(wkb_geometry) = 1;

drop table if exists casablanca_aoi;
create table casablanca_aoi as (select ST_Convexhull(ST_Collect(wkb_geometry)) as geom
                                from casablanca);

-- create table with Casablanca buildings from neural network dataset (1st stage)
drop table if exists casablanca_phase1;
create table casablanca_phase1 as (
    select *
    from morocco_buildings_valid
    where ST_Intersects(ST_Transform(geom, 3857), (select geom from casablanca_aoi))
);

-- update table with the same SRIDs
update casablanca_aoi
set geom = ST_Transform(geom, 3857);

update casablanca_phase1
set geom = ST_MakeValid(ST_Transform(geom, 3857));

-- find building corresponding to the manual selected buildings in Сasablanca (manual)
update casablanca_phase1
set geom = ST_Intersection(geom, (select geom from casablanca_aoi));

-- add column to find buildings footprint
alter table casablanca
    add column footprint geometry;

update casablanca
set footprint = wkb_geometry;

-- first IoU metrics without translation calculations: 0.50
select ST_Area(
               ST_Intersection(
                           (select ST_Union(footprint) from casablanca),
                           (select ST_Union(geom) from casablanca_phase1)
                   )
           ) / ST_Area(
               ST_Union(
                           (select ST_Union(footprint) from casablanca),
                           (select ST_Union(geom) from casablanca_phase1)
                   )
           );

-- union and group by building_height manual selected buildings
drop table if exists casablanca_union;
create table casablanca_union as (
    select (ST_Dump(ST_Union(wkb_geometry))).geom as geom, building_height
    from casablanca
    group by building_height
);

-- union and group by building_height 1st stage selected buildings
drop table if exists casablanca_phase1_union;
create table casablanca_phase1_union as (
    select (ST_Dump(
            ST_Union(geom))).geom as geom,
           building_height
    from casablanca_phase1
    group by building_height
);

alter table casablanca_union
    add column phase_1 geometry;

-- add geometry from 1st stage intersected with manual data
update casablanca_union a
set phase_1 = (select ST_Union(geom) from casablanca_phase1 b where ST_Intersects(a.geom, ST_Pointonsurface(b.geom)));

-- calculations of X and Y shifts
select percentile_cont(0.5) within group (order by (building_height::double precision /
                                                    (ST_X(ST_Centroid(geom)) - ST_X(ST_Centroid(phase_1))))) as X,
       percentile_cont(0.5) within group (order by (building_height::double precision /
                                                    (ST_Y(ST_Centroid(geom)) - ST_Y(ST_Centroid(phase_1))))) as Y
from casablanca_union;

-- update geometry with X and Y corrections
alter table casablanca
    alter column building_height type float USING building_height::double precision;

update casablanca
set footprint = ST_Translate(wkb_geometry, building_height / -1.46, building_height / -3.4);

-- second calculations of IoU metrics with translation corrections: 0.61

select ST_Area(
               ST_Intersection(
                           (select ST_Union(footprint) from casablanca),
                           (select ST_Union(geom) from casablanca_phase1)
                   )
           ) / ST_Area(
               ST_Union(
                           (select ST_Union(footprint) from casablanca),
                           (select ST_Union(geom) from casablanca_phase1)
                   )
           );

-- 3D
-- create indexes for geometry in tables
create index on casablanca using gist (wkb_geometry);
create index on casablanca_phase1 using gist (geom);

-- create table with union manual and 1st stage building polygons
update casablanca_phase1
set geom = ST_Collectionhomogenize(geom);
update casablanca
set wkb_geometry = ST_Collectionhomogenize(wkb_geometry);

drop table if exists casablanca_polygons;
create table casablanca_polygons as (select wkb_geometry as geom
                                     from casablanca
                                     union all
                                     select (ST_Dump(geom)).geom
                                     from casablanca_phase1);

-- create table with all dropped polygon parts of union buildings dataset: 0.51
drop table if exists casablanca_iou_linework;
create table casablanca_iou_linework as
with casablanca_edges as (
    select (ST_Dump(ST_UnaryUnion(ST_Collect(ST_Boundary(geom))))).geom
    from casablanca_polygons
),
     casablanca_parts as (
         select (ST_Dump(ST_Polygonize(geom))).geom
         from casablanca_edges
     ),
     casablanca_parts_count as (
         select casablanca_parts.geom, count(*)
         from casablanca_parts
                  join casablanca_polygons p
                       on ST_Intersects(p.geom, ST_PointOnSurface(casablanca_parts.geom))
         group by casablanca_parts.geom
     )
select *
from casablanca_parts;

-- add columns with min and max building height values
alter table casablanca_iou_linework
    add column min_height float;
alter table casablanca_iou_linework
    add column max_height float;

-- update null values into columns to zero values
update casablanca_iou_linework
set min_height = 0,
    max_height = 0;

-- set min and max building height to the dropped building polygons from 1st stage dataset
create index on casablanca_iou_linework using gist (geom);
create index on casablanca_phase1 using gist (geom);

update casablanca_iou_linework a
set min_height = (select max(building_height)
                  from casablanca_phase1 b
                  where ST_Intersects(ST_PointOnSurface(a.geom), b.geom));
update casablanca_iou_linework a
set max_height = (select max(building_height::float)
                  from casablanca b
                  where ST_Intersects(ST_PointOnSurface(a.geom), b.wkb_geometry));

-- update null values into min anf max building height columns to zero values
update casablanca_iou_linework
set min_height = 0
where min_height is null;
update casablanca_iou_linework
set max_height = 0
where max_height is null;

-- update min and max building height values on ascending order
update casablanca_iou_linework
set min_height = least(min_height, max_height),
    max_height = greatest(max_height, min_height);

-- calculate IoU metrics for all 3D buildings in Casablanca: 0.34
select sum(min_height * ST_Area(geom)) as intersection,
       sum(max_height * ST_Area(geom)),
       sum(min_height * ST_Area(geom)) / sum(max_height * ST_Area(geom))
from casablanca_iou_linework;

-- calculate IoU metrics for every building in Casablanca
-- сreate table with corresponding geometries of buildings from union manual and 1st stage datasets
drop table if exists casablanca_iou_feature;
create table casablanca_iou_feature as (
    select wkb_geometry    as geom_casablanca,
           building_height as building_height_casablanca,
           null::geometry  as geom_phase1,
           null::float     as building_height_phase1
    from casablanca
);

-- update 1st stage geometry values
update casablanca_iou_feature a
set geom_phase1 = (select geom
                   from casablanca_phase1 b
                   where ST_Intersects(ST_PointOnSurface(ST_MakeValid(geom_casablanca)), b.geom)
                     and ST_Intersects(ST_PointOnSurface(b.geom), ST_MakeValid(a.geom_casablanca))
                   order by (ST_Area(ST_Intersection(ST_MakeValid(a.geom_casablanca), b.geom)) /
                             ST_Area(ST_Union(ST_MakeValid(a.geom_casablanca), b.geom))) desc
                   limit 1);

-- update 1st stage building_height values
update casablanca_iou_feature a
set building_height_phase1 = (select building_height
                              from casablanca_phase1 b
                              where ST_Intersects(ST_PointOnSurface(ST_MakeValid(geom_casablanca)), b.geom)
                                and ST_Intersects(ST_PointOnSurface(b.geom), ST_MakeValid(a.geom_casablanca))
                              order by (ST_Area(ST_Intersection(ST_MakeValid(a.geom_casablanca), b.geom)) /
                                        ST_Area(ST_Union(ST_MakeValid(a.geom_casablanca), b.geom))) desc
                              limit 1);

-- insert geometry and building_height values into casablanca_iou_feature table
insert into casablanca_iou_feature (geom_phase1, building_height_phase1)
select geom, building_height
from casablanca_phase1
where geom not in (select geom_phase1 from casablanca_iou_feature);

-- update null 1st stage's geometry values in casablanca_iou_feature table
update casablanca_iou_feature
set geom_phase1 = 'SRID=3857; POLYGON EMPTY'
where geom_phase1 is null;

-- update null 1st stage's building_height values in casablanca_iou_feature table to zero values
update casablanca_iou_feature
set building_height_phase1 = 0
where building_height_phase1 is null;

-- update null manual's geometry values in casablanca_iou_feature table
update casablanca_iou_feature
set geom_casablanca = 'SRID=3857; POLYGON EMPTY'
where geom_casablanca is null;

-- update null manual's building_height values in casablanca_iou_feature table to zero values
update casablanca_iou_feature
set building_height_casablanca = 0
where building_height_casablanca is null;

-- calculate average IoU metrics of every buildings: 0.19
select avg(ST_Area(ST_Intersection(ST_makevalid(geom_casablanca), ST_makevalid(geom_phase1))) / ST_Area(ST_Union(ST_makevalid(geom_casablanca), ST_makevalid(geom_phase1))))
from casablanca_iou_feature;
