drop table if exists abu_dhabi_shops;
create table abu_dhabi_shops as (
    select o.osm_id,
           o.tags ->> 'name'    as name,
           o.tags ->> 'amenity' as type,
           o.tags,
           o.geog::geometry     as geom
    from osm o,
         abu_dhabi_admin_boundaries d
    where o.tags ? 'amenity'
      and o.tags ->> 'amenity' in
          ('bar', 'biergarten', 'cafe', 'fast_food', 'food_court', 'ice_cream', 'pub', 'restaurant')
      and ST_Intersects(d.geom, o.geog::geometry)
    union all
    select o.osm_id,
           o.tags ->> 'name' as name,
           o.tags ->> 'shop' as type,
           o.tags,
           o.geog::geometry  as geom
    from osm o,
         abu_dhabi_admin_boundaries d
    where o.tags ? 'shop'
      and o.tags ->> 'shop' in ('convenience', 'general', 'greengrocer', 'kiosk', 'supermarket')
      and ST_Intersects(d.geom, o.geog::geometry)
);

drop table if exists abu_dhabi_pop_shops;
create table abu_dhabi_pop_shops as (
    select k.h3, k.area, k.population, count(s) "shops", k.geom
    from kontur_population_h3 k,
         abu_dhabi_admin_boundaries b,
         abu_dhabi_shops s
    where k.resolution = 8
      and ST_Intersects(k.geom, ST_Transform(b.geom, 3857))
      and ST_Intersects(k.geom, ST_Transform(s.geom, 3857))
    group by k.h3, k.area, k.population, k.geom
);

drop table abu_dhabi_shops;

drop table if exists abu_dhabi_bivariate_pop_shops;
create table abu_dhabi_bivariate_pop_shops as (
    select *, chr(64 + ntile(3) over (order by shops)) || ntile(3) over (order by population) "bivariate_cell"
    from abu_dhabi_pop_shops
);
