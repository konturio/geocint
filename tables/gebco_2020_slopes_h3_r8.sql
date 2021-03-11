alter table gebco_2020_slopes
    set (parallel_workers = 32);

drop table if exists gebco_2020_slopes_h3_r8;
create table gebco_2020_slopes_h3_r8 as (
    select h3,
           8    as resolution,
           avg(avg_slope) as avg_slope
    from (
            select h3_geo_to_h3(ST_Transform(geom, 4326)::point, 8) as h3,
            avg(val)                                       as avg_slope
             from (
                      select p.geom, p.val
                      from gebco_2020_slopes,
                           ST_PixelAsCentroids(rast) p
                  ) z
         ) x
    group by 1
);
