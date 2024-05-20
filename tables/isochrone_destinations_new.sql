drop table if exists isochrone_destinations_new_in;
create table isochrone_destinations_new_in as (
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
           'bomb_shelter' as type,
           tags,
           ST_Centroid(geog::geometry) as geom
    from osm o
    where tags @> '{"building":"bunker"}'
       or tags @> '{"military":"bunker"}'
    order by osm_id
);

drop table if exists isochrone_destinations_new;
create table isochrone_destinations_new as (
    select osm_id,
           type,
           tags,
           geom 
    from isochrone_destinations_new_in
    union all
    select osm_id,
           "food_shops_eatery" as type,
           tags,
           geom
    from osm_places_eatery
    union all
    select osm_id,
           "food_shops_eatery" as type,
           tags,
           geom
    from osm_places_food_shops
);

drop table if exists isochrone_destinations_new_in;