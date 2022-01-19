drop table if exists isochrone_destinations_new;
create table isochrone_destinations_new as (
    select osm_id,
           tags ->> 'amenity'             "type",
           tags,
           ST_Centroid(geog::geometry) as geom
    from osm o
    where tags @> '{"amenity":"fire_station"}'
       or tags @> '{"amenity":"hospital"}'
    order by osm_id
);
