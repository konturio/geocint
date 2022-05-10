drop table if exists :table_name_h3;

create table :table_name_h3 as (
    select h3,
           8 as resolution,
           :item_name
    from (
            select h3_geo_to_h3(geom::point, 8) as h3,
            :aggr_func(val) as :item_name
             from (
                     select p.geom, p.val
                     from :table_name,
                          ST_PixelAsCentroids(rast) p
                  ) z
            group by 1
         ) x
);
