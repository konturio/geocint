alter table copernicus_landcover_raster
    set (parallel_workers = 32);

drop table if exists copernicus_builtup_h3;
create table copernicus_builtup_h3 as (
    select h3,
           8          as resolution,
           sum(count) as count
    from (
             select h3_geo_to_h3(ST_Transform(geom, 4326)::point, 8) as h3,
                    count(val)                                       as count
             from (
                      select p.geom, p.val
                      from copernicus_landcover_raster,
                           ST_PixelAsCentroids(rast) p
                  ) z
             where val = 50
             group by 1
         ) x
    group by 1
);
