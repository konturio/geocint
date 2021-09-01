drop table if exists osm_water_polygons_in_subdivided;

create table osm_water_polygons_in_subdivided as (
    select osm_type,
           osm_id,
           ST_Subdivide(ST_Transform(geog::geometry, 3857), 100) as geom
    from osm
    where (tags ? 'water'
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
      and ST_GeometryType(geog::geometry) != 'ST_LineString');