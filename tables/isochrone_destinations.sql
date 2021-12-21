drop table if exists isochrone_destinations;
create table isochrone_destinations as (
    select osm_id,
           tags ->> 'amenity'             "type",
           tags,
           ST_Centroid(geog::geometry) as geom
    from osm o
    where tags @> '{"amenity":"fire_station"}'
       or tags @> '{"amenity":"hospital"}'
);
create index on isochrone_destinations using gist (geom);
