drop table if exists osm_water_polygons;

create table osm_water_polygons as (
  select
    osm_type,
    osm_id,
    ST_Area(geog)                      as area,
    ST_Transform(geog::geometry, 3857) as geom
  from
    osm
  where
    ((tags ->> 'natural') = 'water' or (tags ->> 'waterway') in ('riverbank', 'river', 'stream', 'canal') or (tags ->> 'water') is not null)
    and ST_GeometryType(geog::geometry) != 'ST_Point'
    and ST_GeometryType(geog::geometry) != 'ST_LineString'
);

create index on osm_water_polygons using gist (geom);
