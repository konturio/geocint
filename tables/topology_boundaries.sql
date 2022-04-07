drop table if exists topology_boundary_in;
create table topology_boundary_in as
select
    osm_id,
    kontur_admin_level as admin_level,
    false as maritime,
    ST_Transform(ST_Boundary((ST_DumpRings((ST_Dump(geom)).geom)).geom), 3857) as geom
from kontur_boundaries
where admin_level is not null;

-- add maritime (laying on water) boundaries in topology_boundary_in
with maritime_boundaries as (
    select
       osm_id,
       admin_level,
       true as maritime,
       (ST_Dump(ST_Intersection(topology_boundary_in.geom,
           (select ST_Union(geom) from water_polygons_vector where ST_Intersects(topology_boundary_in.geom, water_polygons_vector.geom))))).geom as geom
    from topology_boundary_in
    where exists(select from water_polygons_vector where ST_Intersects(topology_boundary_in.geom, water_polygons_vector.geom))
) insert into topology_boundary_in (osm_id, admin_level, maritime, geom)
select
    osm_id,
    admin_level,
    maritime,
    geom
from maritime_boundaries
where ST_Dimension(geom) = 1;

-- clip water from not maritime boundaries
update topology_boundary_in
set geom = ST_Difference(topology_boundary_in.geom,
    (select ST_Union(geom) from water_polygons_vector where ST_Intersects(topology_boundary_in.geom, water_polygons_vector.geom)))
where maritime = false and exists(select from water_polygons_vector where ST_Intersects(topology_boundary_in.geom, water_polygons_vector.geom));

-- Dump to segments and remove repeated
drop table if exists topology_boundary_mid;
create table topology_boundary_mid as
    select min(osm_id) as osm_id, min(admin_level) as admin_level, bool_or(maritime) as maritime, geom
    from (select ST_Normalize((ST_DumpSegments(geom)).geom) as geom, osm_id, admin_level, maritime 
        from topology_boundary_in) as squ
    group by geom;

create index on topology_boundary_mid using btree(osm_id, admin_level, maritime);

drop table if exists topology_boundary;
create table topology_boundary as
select osm_id, admin_level, maritime, (ST_Dump(ST_LineMerge(ST_Union(geom)))).geom as geom
from topology_boundary_mid
group by osm_id, admin_level, maritime;

drop table if exists topology_boundary_in;
drop table if exists topology_boundary_mid;
