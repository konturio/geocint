drop table if exists isochrone_destinations_new;
create table isochrone_destinations_new as (
    select osm_id,
           tags ->> 'amenity'             "type",
           tags,
           ST_Centroid(geog::geometry) as geom
    from osm o
    where tags @> '{"amenity":"fire_station"}'
       or tags @> '{"amenity":"hospital"}'
       or tags @> '{"amenity":"charging_station"}'
    union all
    select osm_id,
           'port' as type,
           tags,
           ST_Centroid(geog::geometry) as geom
    from osm o
    where tags @> '{"landuse":"port"}'
       or (tags @> '{"landuse":"industrial"}' and tags @> '{"industrial":"port"}')
       or tags @> '{"harbour":"port"}'
       or tags @> '{"harbour":"yes"}'
    union all
    select osm_id,
           'bomb_shelter' as type,
           tags,
           ST_Centroid(geog::geometry) as geom
    from osm o
    where tags @> '{"building":"bunker"}'
       or tags @> '{"military":"bunker"}'
    order by osm_id
);
