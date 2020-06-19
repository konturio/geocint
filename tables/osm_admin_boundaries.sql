drop table if exists osm_admin_boundaries;
create table osm_admin_boundaries as (
    select osm_id,
           osm_type,
           tags ->> 'boundary'    as boundary,
           tags ->> 'admin_level' as admin_level,
           tags ->> 'name'        as "name",
           tags,
           geog::geometry         as geom
    from osm
    where tags ? 'admin_level'
      and tags @>
          '{"boundary":"administrative"}'
      and (tags ->> 'admin_level') in ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11')
);
