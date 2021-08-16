drop table if exists abu_dhabi_shops;
create table abu_dhabi_shops as (
    select o.osm_id,
           o.tags ->> 'shop'             as type,
           ST_Centroid(o.geog::geometry) as geom
    from osm o,
         abu_dhabi_admin_boundaries b
    where ST_Intersects(b.geom, o.geog::geometry)
      and o.tags ? 'shop'
      and o.tags ->> 'shop' in
          ('convenience', 'general', 'greengrocer', 'kiosk', 'supermarket')
);
