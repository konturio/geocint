drop table if exists abu_dhabi_bivariate_pop_shops;
create table abu_dhabi_bivariate_pop_shops as (
    with abu_dhabi_shops as (
        select h3_geo_to_h3(o.geog::geometry::box::point, 8) "h3",
               count(o)                                      "shops"
        from osm o,
             abu_dhabi_admin_boundaries b
        where ST_Intersects(b.geom, o.geog::geometry)
          and (
                (
                            o.tags ? 'amenity'
                        and o.tags ->> 'amenity' in
                            ('bar', 'biergarten', 'cafe', 'fast_food', 'food_court', 'ice_cream', 'pub',
                             'restaurant')
                    ) or (
                            o.tags ? 'shop'
                        and o.tags ->> 'shop' in
                            ('convenience', 'general', 'greengrocer', 'kiosk', 'supermarket')
                    )
            )
        group by 1
    )
    select s.h3,
           s.shops,
           pop                                                                        "population",
           chr(64 + ntile(3) over (order by s.shops)) || ntile(3) over (order by pop) "bivariate_cell"
    from abu_dhabi_shops s
             left outer join kontur_population_h3 k on (k.resolution = 8 and s.h3 = k.h3),
         coalesce(k.population, 0) pop
);
