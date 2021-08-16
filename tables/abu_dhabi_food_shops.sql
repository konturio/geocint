drop table if exists abu_dhabi_food_shops;
create table abu_dhabi_food_shops as (
    select o.osm_id,
           o.tags ->> 'shop'             as type,
           ST_Centroid(o.geog::geometry) as geom
    from osm o,
         abu_dhabi_admin_boundaries b
    where ST_Intersects(b.geom, o.geog::geometry)
      and o.tags ? 'shop'
      and o.tags ->> 'shop' in
          ('alcohol', 'bakery', 'beverages', 'brewing_supplies', 'butcher', 'cheese', 'chocolate', 'coffee',
           'confectionery', 'convenience', 'deli', 'dairy', 'farm', 'frozen_food', 'greengrocer', 'health_food',
           'ice_cream', 'pasta', 'pastry', 'seafood', 'spices', 'tea', 'water', 'department_store', 'general', 'kiosk',
           'mall', 'supermarket', 'wholesale')
);
