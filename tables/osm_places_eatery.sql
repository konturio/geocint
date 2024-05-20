drop table if exists osm_places_eatery;
create table osm_places_eatery as (
    select ST_Centroid(o.geog::geometry) as geom,
           o.osm_id,
           o.tags ->> 'amenity'          as type,
           o.tags                        as tags
    from osm o
    where o.tags ? 'amenity'
      and o.tags ->> 'amenity' in
          ('bar', 'biergarten', 'cafe', 'fast_food', 'food_court', 'ice_cream', 'pub', 'restaurant')
);

create index on osm_places_eatery using gist (geom);