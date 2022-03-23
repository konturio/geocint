-- Transform water_polygons to 4326
drop table if exists water_polygons_4326;
create table water_polygons_4326 as
	select gid,
           ST_Transform(geom, 4326) as geom
    from water_polygons_vector;    

-- Clip water polys from osm_boundaries
drop table if exists topology_boundary_in;
create table topology_boundary_in as
select k.kontur_admin_level          as admin_level,
       ST_Difference(k.geom, w.geom) as geom
from kontur_boundaries     as k,
     water_polygons_4326   as w;

drop table if exists water_polygons_4326;

-- Dump to segments and remove repeated
drop table if exists topology_boundary;
create table topology_boundary as
       select distinct on (geom) admin_level,
                                 geom
       from (select (ST_DumpSegments(geom)).geom, 
                     admin_level 
             from topology_boundary_in) as squ
       order by geom, admin_level;

drop table if exists topology_boundary_in;
create index on topology_boundary using gist(geom);