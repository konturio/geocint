drop table if exists ndvi_2019_06_10_h3;
create table ndvi_2019_06_10_h3 as (
    select h3,
           8    as resolution,
           avg_ndvi
    from (
            select h3_geo_to_h3(geom::point, 8) as h3,
            avg(val)                                     as avg_ndvi
             from (
                      select p.geom, p.val
                      from ndvi_2019_06_10,
                           ST_PixelAsCentroids(rast) p
                      where val != 'NaN'
                  ) z
            group by 1
         ) x
);
