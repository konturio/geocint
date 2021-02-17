-- fix assertions inline
-- TODO: move to other flows
update :reference_buildings_table set geom = ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 3857)), 3) where ST_SRID(geom)!=3857 or not ST_IsValid(geom);
update :examinee_buildings_table set geom = ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 3857)), 3) where ST_SRID(geom)!=3857 or not ST_IsValid(geom);



-- Calculation IoU metrics for all buildings from test benchmark

-- Step 1. Import data and reformat it.

-- Import the JSON files:
-- ogr2ogr PG:"" morocco_buildings_manual.geojson
-- ogr2ogr PG:"" morocco_buildings_benchmark_aoi.geojson
drop table if exists metrics_storage;
create table metrics_storage (
    city   text, -- name of city
    metric text, -- name of metric
    type   text, -- roof or foot
    value  float -- number
);

-- Parameters:
-- reference_buildings_table
-- benchmark_clip_table
-- examinee_buildings_table
-- type

-- Clip ground truth to clip polygons
drop table if exists x_buildings_reference;
create table x_buildings_reference as (
    select b.is_confident,
           b.building_height,
           ST_Intersection(b.geom, a.geom) as geom,
           a.city
    from :reference_buildings_table b
         join :benchmark_clip_table a
              on ST_Intersects(b.geom, a.geom)
);
create index on x_buildings_reference using gist (geom);

insert into metrics_storage (city, metric, type, value)
select city, 'Validation polygons', :'type', count(*)
from x_buildings_reference
group by city;

insert into metrics_storage (city, metric, type, value)
select city, 'Validation polygons with verified height', :'type', count(*)
from x_buildings_reference
where is_confident is true
group by city;

-- Clip examinee to clip polygons
drop table if exists x_buildings_examinee;
create table x_buildings_examinee as (
    select b.building_height,
           ST_Intersection(b.geom, a.geom) as geom,
           a.city
    from :examinee_buildings_table  b
         join :benchmark_clip_table a
              on ST_Intersects(b.geom, a.geom)
);
create index on x_buildings_examinee using gist (geom);

insert into metrics_storage (city, metric, type, value)
select city, 'Phase 2 detected polygons', :'type', count(*)
from x_buildings_examinee
group by city;

-- Step 2. Generate min / max heights map on the pieces of input geometry
-- collect both sets into one table
drop table if exists x_buildings_both;
create table x_buildings_both as (
    select city, geom as geom
    from x_buildings_reference
    union all
    select city, geom
    from x_buildings_examinee
);

delete
from x_buildings_both
where ST_Dimension(ST_Boundary(geom)) is null;

delete
from x_buildings_both
where ST_Dimension(ST_Boundary(geom)) = 2;

-- generate the breakout table with polygons of all candidate pieces
drop table if exists x_buildings_chunks;
create table x_buildings_chunks as
with edges as (
    select (ST_Dump(ST_UnaryUnion(ST_Collect(ST_Boundary(geom))))).geom
    from x_buildings_both
)
select (ST_Dump(ST_Polygonize(geom))).geom,
       0::float as min_height,
       0::float as max_height,
       ''::text as city
from edges;
create index on x_buildings_chunks using gist (geom);

-- for each piece, get heights from both datasets. will swap them later.
update x_buildings_chunks a
set min_height = coalesce((
    select max(building_height)
    from x_buildings_reference b
    where ST_Intersects(ST_PointOnSurface(a.geom), b.geom)
      and a.geom && b.geom
),0);

update x_buildings_chunks a
set max_height = coalesce((
    select max(building_height)
    from x_buildings_examinee b
    where ST_Intersects(ST_PointOnSurface(a.geom), b.geom)
      and a.geom && b.geom
),0);

-- swap min and max to be correct
update x_buildings_chunks
set min_height = least(min_height, max_height),
    max_height = greatest(max_height, min_height);

-- if min and max height are 0, it is likely a polygonization artifact, so remove
delete
from x_buildings_chunks
where min_height = 0
  and max_height = 0;

-- Step 3. Calculate IoU in 2D and 3D
-- calculate 2D IoU metrics
insert into metrics_storage (city, metric, type, value)
select b.city, '2D_IoU', :'type', sum(ST_Area(a.geom)) filter (where min_height > 0) / sum(ST_Area(a.geom))
from x_buildings_chunks         a
     join :benchmark_clip_table b
          on ST_Intersects(a.geom, b.geom)
group by b.city;

-- calculate 3D IoU metrics
insert into metrics_storage (city, metric, type, value)
select b.city, '3D_IoU', :'type', sum(min_height * ST_Area(a.geom)) / sum(max_height * ST_Area(a.geom))
from x_buildings_chunks         a
     join :benchmark_clip_table b
          on ST_Intersects(a.geom, b.geom)
group by b.city;

-- Step 4. Generate feature-to-feature IoU.
-- table for the matching geometries
drop table if exists x_buildings_iou_feature;
create table x_buildings_iou_feature as (
    select distinct geom as geom_ref,
                    building_height as height_ref,
                    null::geometry as geom_exa,
                    null::float as height_exa,
                    is_confident
    from x_buildings_reference
);
create index on x_buildings_iou_feature using gist (geom_ref);
create index on x_buildings_iou_feature using gist (geom_exa);

-- match geometries if representative point on one is inside other and vice versa.
-- in case of collision take option with better IoU.
update x_buildings_iou_feature a
set geom_exa = (
    select geom
    from x_buildings_examinee b
    where ST_Intersects(ST_PointOnSurface(a.geom_ref), b.geom)
      and ST_Intersects(ST_PointOnSurface(b.geom), a.geom_ref)
    order by (ST_Area(ST_Intersection(a.geom_ref, b.geom)) /
              ST_Area(ST_Union(a.geom_ref, b.geom))) desc
    limit 1
);

update x_buildings_iou_feature a
set height_exa = (
    select building_height
    from x_buildings_examinee b
    where ST_Intersects(ST_PointOnSurface(a.geom_ref), b.geom)
      and ST_Intersects(ST_PointOnSurface(b.geom), a.geom_ref)
    order by (ST_Area(ST_Intersection(a.geom_ref, b.geom)) /
              ST_Area(ST_Union(a.geom_ref, b.geom))) desc
    limit 1
);

-- append the geometries not referenced by other side
insert into x_buildings_iou_feature (geom_exa, height_exa)
select geom, building_height
from x_buildings_examinee
where geom not in ( select geom_exa from x_buildings_iou_feature where geom_exa is not null );

-- zero out NULLs into 0/EMPTY
update x_buildings_iou_feature set geom_exa = 'SRID=3857; POLYGON EMPTY' where geom_exa is null;
update x_buildings_iou_feature set height_exa = 0 where height_exa is null;
update x_buildings_iou_feature set geom_ref = 'SRID=3857; POLYGON EMPTY' where geom_ref is null;
update x_buildings_iou_feature set height_ref = 0 where height_ref is null;

delete from x_buildings_iou_feature where ST_IsEmpty(geom_exa) and ST_IsEmpty(geom_ref);

-- calculate average IoU metrics of every buildings
insert into metrics_storage (city, metric, type, value)
select a.city,
       'Per-segment_IoU',
       :'type',
       avg(ST_Area(ST_Intersection(geom_exa, geom_ref)) /
           ST_Area(ST_Union(geom_exa, geom_ref)))
from x_buildings_iou_feature    m
     join :benchmark_clip_table a
          on ST_Intersects(ST_Union(ST_PointOnSurface(geom_exa), ST_PointOnSurface(geom_ref)), a.geom)
group by 1;


insert into metrics_storage (city, metric, type, value)
select a.city,
       'Per-segment_IoU_excluding_not_matched',
       :'type',
       avg(ST_Area(ST_Intersection(geom_exa, geom_ref)) /
           ST_Area(ST_Union(geom_exa, geom_ref)))
from x_buildings_iou_feature    m
     join :benchmark_clip_table a
          on ST_Intersects(ST_Union(ST_PointOnSurface(geom_exa), ST_PointOnSurface(geom_ref)), a.geom)
where not ST_IsEmpty(geom_exa)
  and not ST_IsEmpty(geom_ref)
group by 1;

-- Step 5. Height metrics
-- calculate Height RMSD in meters
insert into metrics_storage (city, metric, type, value)
select a.city, 'Height_RMSD', :'type', sqrt(avg(power(height_exa - height_ref, 2)))
from x_buildings_iou_feature    m
     join :benchmark_clip_table a
          on ST_Intersects(ST_Union(ST_PointOnSurface(geom_exa), ST_PointOnSurface(geom_ref)), a.geom)
where height_exa > 0
  and height_ref > 0
group by 1;

-- calculate Height RMSD in metres where is_confident = true
insert into metrics_storage (city, metric, type, value)
select a.city, 'Height_RMSD_verified', :'type', sqrt(avg(power(height_exa - height_ref, 2)))
from x_buildings_iou_feature    m
     join :benchmark_clip_table a
          on ST_Intersects(ST_Union(ST_PointOnSurface(geom_exa), ST_PointOnSurface(geom_ref)), a.geom)
where height_exa > 0
  and height_ref > 0
  and is_confident
group by 1;