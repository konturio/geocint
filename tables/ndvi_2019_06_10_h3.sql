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
                      from ndvi_2019_06_10_h3,
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
                insert into ndvi_2019_06_10_h3 (h3, avg_ndvi, resolution)
                select h3_to_parent(h3) as h3, avg(avg_ndvi) as avg_ndvi, (res - 1) as resolution
                from ndvi_2019_06_10_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;


create index on ndvi_2019_06_10_h3 (h3, avg_ndvi);
