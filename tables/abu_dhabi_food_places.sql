drop table if exists abu_dhabi_food_places;
create table abu_dhabi_food_places as (
    select o.osm_id, o.tags ->> 'name' "name", o.tags ->> 'amenity' "type", o.tags, o.geog::geometry "geom"
    from osm o,
         abu_dhabi_admin_boundaries d
    where o.tags ? 'amenity'
      and o.tags ->> 'amenity' in ('bar', 'biergarten', 'cafe', 'fast_food', 'food_court', 'ice_cream', 'pub', 'restaurant')
      and ST_Intersects(d.geom, o.geog::geometry)
    union all
    select o.osm_id, o.tags ->> 'name' "name", o.tags ->> 'shop' "type", o.tags, o.geog::geometry "geom"
    from osm o,
         abu_dhabi_admin_boundaries d
    where o.tags ? 'shop'
      and o.tags ->> 'shop' in ('convenience', 'general', 'greengrocer', 'kiosk', 'supermarket')
      and ST_Intersects(d.geom, o.geog::geometry)
);
