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
          tags @> '{"foot":"yes"}' or
          tags @> '{"highway":"residential"}' or
          tags @> '{"highway":"service"}' or
          tags @> '{"highway":"track"}' or
          tags @> '{"highway":"living_street"}' or
          tags @> '{"highway":"pedestrian"}' or
          tags @> '{"highway":"footway"}' or
          tags @> '{"sidewalk":"left"}' or
          tags @> '{"sidewalk":"right"}' or
          tags @> '{"sidewalk":"both"}' or
          tags @> '{"sidewalk":"yes"}'
        then
          ST_Length(seg_geom::geography) / 1.4 -- 5 km/hr
      when
          tags @> '{"foot":"no"}' or
          tags @> '{"access":"no"}' or
          tags @> '{"highway":"proposed"}' or
          tags @> '{"highway":"motorway"}' or
          tags @> '{"highway":"motorway_link"}' or
          tags @> '{"highway":"trunk"}' or
          tags @> '{"highway":"trunk_link"}' or
          tags @> '{"highway":"primary"}' or
          tags @> '{"highway":"primary_link"}' or
          tags @> '{"highway":"secondary"}' or
          tags @> '{"highway":"secondary_link"}' or
          tags @> '{"tunnel":"yes"}'
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