drop table if exists osm_road_segments;
create table osm_road_segments as (
  select
    seg_id,
    node_from,
    node_to,
    seg_geom,
    -- TODO: elevation profile
    ST_Length(seg_geom::geography) as length,
    case
      when
        tags @> '{"foot":"yes"}'
        then
        ST_Length(seg_geom::geography) / 1.4 -- 5 km/hr
      when
          tags @> '{"foot":"no"}' or
          tags @> '{"access":"no"}' or
          tags @> '{"highway":"motorway"}' or
          tags @> '{"highway":"trunk"}' or
          tags @> '{"highway":"primary"}' or
          tags @> '{"highway":"secondary"}'
        then null
      when
          tags @> '{"highway":"steps"}' or
          tags @> '{"highway":"cycleway"}'
        then
        ST_Length(seg_geom::geography) / 1.0 -- 3.6 km/hr
      else
        ST_Length(seg_geom::geography) / 1.4 -- 5 km/hr
      end                          as walk_time
  from
    osm o,
    osm_way_nodes_to_segments(geog::geometry, way_nodes, osm_id) z
  where
    tags ? 'highway'
    and osm_type = 'way'
    and ST_GeometryType(geog::geometry) != 'ST_MultiPolygon'
    -- TODO: teach osmium to export Polygon (https://github.com/osmcode/osmium-tool/issues/153)
    and ST_GeometryType(geog::geometry) != 'ST_Polygon'
  order by seg_geom
);