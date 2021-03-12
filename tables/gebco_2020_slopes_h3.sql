alter table gebco_2020_slopes
    set (parallel_workers = 32);

drop table if exists gebco_2020_slopes_h3;
create table gebco_2020_slopes_h3 as (
    select h3,
           8    as resolution,
           avg_slope
    from (
            select h3_geo_to_h3(geom::point, 8) as h3,
            avg(val)                                     as avg_slope
             from (
                      select p.geom, p.val
                      from gebco_2020_slopes,
                           ST_PixelAsCentroids(rast) p
                  ) z
            group by 1
         ) x
);


do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into gebco_2020_slopes_h3 (h3, avg_slope, resolution)
                select h3_to_parent(h3) as h3, avg(avg_slope) as avg_slope, (res - 1) as resolution
                from gebco_2020_slopes_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;