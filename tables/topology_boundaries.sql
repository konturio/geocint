-- Transform water_polygons to 4326
drop table if exists water_polygons_4326;
create table water_polygons_4326 as
	select gid,
           ST_Transform(geom, 4326) as geom
    from water_polygons_vector;    

-- Clip water polys from osm_boundaries
drop table if exists topology_boundary_in;
create table topology_boundary_in as
select k.osm_id, 
       k.gadm_id, 
       k.admin_level,
       ST_Difference(k.geom, w.geom) as geom
from kontur_boundaries     as k,
     water_polygons_4326   as w;

drop table if exists water_polygons_4326;

-- Transform osm_boundaries from polys to lines
drop table if exists topology_boundary_mid1;
create table topology_boundary_mid as
    select k.osm_id, 
           k.gadm_id, 
           k.admin_level,
           ST_Boundary(geom) as geom
    from topology_boundary_in;

-- Remove repeated borders with admin_level > min
drop table if exists topology_boundary_mid2;
create table topology_boundary_mid2 as
	select k.osm_id, 
           k.gadm_id, 
           k.admin_level,
           ST_Difference(k.geom, w.geom) as geom
    from topology_boundary_mid1 k 
    join topology_boundary_mid1 w
    on ST_Intersects(k.geom, w.geom)
    where k.admin_level < w.admin_level;

-- all lines on the level to 1 multilinestring and after create difference

-- Check topology consistency