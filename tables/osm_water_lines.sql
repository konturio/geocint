drop table if exists osm_water_lines;

create table osm_water_lines as (
  select
    osm_type,
    osm_id,
    ST_Transform(geog::geometry, 3857) as geom,
    tags
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
    or tags @> '{"waterway":"drain"}')
    and ST_GeometryType(geog::geometry) = 'ST_LineString'
);

create index on osm_water_lines using brin (geom);