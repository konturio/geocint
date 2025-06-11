drop table if exists isochrone_destinations_new;
create table isochrone_destinations_new as (
    select osm_id,
           tags ->> 'amenity'                     as type,
           tags,
           ST_Centroid(geog::geometry)::geography as geog
    from osm o
    where tags @> '{"amenity":"fire_station"}'
       or tags @> '{"amenity":"hospital"}'
       or tags @> '{"amenity":"charging_station"}'
    union all
    select osm_id,
           'bomb_shelter'                         as type,
           tags,
           ST_Centroid(geog::geometry)::geography as geog
    from osm o
    where tags @> '{"building":"bunker"}'
       or tags @> '{"military":"bunker"}'
    order by osm_id
);
