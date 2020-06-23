drop table if exists osm_admin_boundaries;
create table osm_admin_boundaries as (
    select osm_id,
           osm_type,
           tags ->> 'boundary'    as boundary,
           tags ->> 'admin_level' as admin_level,
           tags ->> 'name'        as "name",
           tags,
           geog::geometry         as geom,
           st_geometrytype(geog::geometry) as types
    from osm
    where tags ? 'admin_level'
      and tags @>
          '{"boundary":"administrative"}'
    and st_geometrytype(geog::geometry) = 'ST_MultiPolygon'
);
