drop table if exists osm_water_polygons;

create table osm_water_polygons as (
  select
    osm_type,
    osm_id,
    ST_Subdivide(ST_Transform(geog::geometry, 3857), 100) as geom
  from
    osm
  where
    (tags ? 'water'
    or tags @> '{"natural":"water"}' 
    or tags @> '{"waterway":"riverbank"}'
    or tags @> '{"waterway":"river"}'
    or tags @> '{"waterway":"stream"}'
    or tags @> '{"waterway":"canal"}'
    or tags @> '{"waterway":"ditch"}'
    or tags @> '{"waterway":"drain"}'
    or tags @> '{"landuse":"reservoir"}'
    )
    and ST_GeometryType(geog::geometry) != 'ST_Point'
    and ST_GeometryType(geog::geometry) != 'ST_LineString'

    union all

    select 
      'oceans' as osm_type, 
      gid as osm_id, 
      geom
    from 
      water_polygons_vector

    union all

    select 
      osm_type, 
      osm_id, 
      ST_Subdivide(ST_Buffer(geom, 1), 100) as geom 
      from 
        osm_water_lines
    order by 3
);

vacuum osm_water_polygons;
create index on osm_water_polygons using gist (geom);
