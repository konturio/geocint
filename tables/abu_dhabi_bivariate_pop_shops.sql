drop table if exists abu_dhabi_bivariate_pop_shops;
create table abu_dhabi_bivariate_pop_shops as (
    with abu_dhabi_pop_shops as (
        select h3,
               coalesce(sum(shops), 0)      "shops",
               coalesce(sum(population), 0) "population"
        from (
                 select h3_geo_to_h3(o.geog::geometry::box::point, 8) "h3",
                        count(o)                                      "shops",
                        null::double precision                        "population"
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
                 union all
                 select h3,
                        null::integer "shops",
                        population
                 from kontur_population_h3 k,
                      abu_dhabi_admin_boundaries b
                 where resolution = 8
                   and ST_Intersects(k.geom, ST_Transform(b.geom, 3857))
                 order by h3
             ) "z"
        group by h3
    )
    select h3,
           shops,
           population,
           chr(64 + ntile(3) over (order by shops)) || ntile(3) over (order by population) "bivariate_cell"
    from abu_dhabi_pop_shops
);
