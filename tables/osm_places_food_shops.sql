drop table if exists osm_places_food_shops;
create table osm_places_food_shops as (
    select ST_Centroid(o.geog::geometry) as geom,
           o.osm_id,
           o.tags ->> 'shop'             as type,
    from osm
        o.tags ? 'shop'
      and o.tags ->> 'shop' in
          ('alcohol', 'bakery', 'beverages', 'brewing_supplies', 'butcher', 'cheese', 'chocolate', 'coffee',
           'confectionery', 'convenience', 'deli', 'dairy', 'farm', 'frozen_food', 'greengrocer', 'health_food',
           'ice_cream', 'pasta', 'pastry', 'seafood', 'spices', 'tea', 'water', 'general', 'kiosk', 'supermarket',
           'wholesale')
);

create index on osm_places_food_shops using gist (geom);