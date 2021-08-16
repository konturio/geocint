drop table if exists abu_dhabi_bivariate_pop_shops;
create table abu_dhabi_bivariate_pop_shops as (
    with places as (
        select h3_geo_to_h3(geom::box::point, 8) "h3", count(p) "places"
        from (
                 select geom
                 from abu_dhabi_eatery
                 union all
                 select geom
                 from abu_dhabi_shops
             ) "p"
        group by 1
    )
    select p.h3,
           pop                                                                         "population",
           p.places,
           chr(64 + ntile(3) over (order by p.places)) || ntile(3) over (order by pop) "bivariate_cell"
    from places p
             left outer join kontur_population_h3 k on (k.resolution = 8 and k.h3 = p.h3),
         coalesce(k.population, 0) pop
);

