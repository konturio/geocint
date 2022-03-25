-- Transform water_polygons to 4326
drop table if exists water_polygons_4326;
create table water_polygons_4326 as
	select gid,
           ST_Transform(geom, 4326) as geom
    from water_polygons_vector;

create index on water_polygons_4326 using gist(geom);

drop table if exists topology_boundary_in;
create table topology_boundary_in as
select kontur_admin_level as admin_level, ST_Boundary((ST_DumpRings((ST_Dump(geom)).geom)).geom) as geom from kontur_boundaries
where admin_level is not null;

-- Clip water polys from osm_boundaries
update topology_boundary_in
set geom = ST_Difference(topology_boundary_in.geom,
       (select ST_Union(geom)
       from water_polygons_4326
       where ST_Intersects(topology_boundary_in.geom, water_polygons_4326.geom)))
where exists(select from water_polygons_4326 where ST_Intersects(topology_boundary_in.geom, water_polygons_4326.geom));

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