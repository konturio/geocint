drop table if exists abu_dhabi_eatery;
create table abu_dhabi_eatery as (
    select o.osm_id,
           o.tags ->> 'amenity'          as type,
           ST_Centroid(o.geog::geometry) as geom
    from osm o,
         abu_dhabi_admin_boundaries b
    where ST_Intersects(b.geom, o.geog::geometry)
      and o.tags ? 'amenity'
      and o.tags ->> 'amenity' in
          ('bar', 'biergarten', 'cafe', 'fast_food', 'food_court', 'ice_cream', 'pub', 'restaurant')
);
