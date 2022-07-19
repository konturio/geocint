drop table if exists night_lights_h3;
-- Set strict mode of h3 library to avoid error with longitude which is slightly more than 180 deg (180.000003)
set h3.strict = 'off';
create table night_lights_h3 as (
    select h3,
           8          as resolution,
           avg(val)   as intensity
    from (
              select h3_geo_to_h3(ST_Transform(p.geom, 4326)::point, 8) as h3, 
                     p.val                                              as val
              from night_lights_raster,
                   ST_PixelAsCentroids(rast) p
              where val > 0
          ) x
    group by 1
);