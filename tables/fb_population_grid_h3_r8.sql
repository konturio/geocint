alter table fb_population_raster
    set (parallel_workers = 32);

create table fb_population_grid_h3_r8 as (
    select
        h3_geo_to_h3(geom::point, 8) as h3,
        8 as resolution,
        sum(val) as population
    from
            ( select (ST_PixelAsCentroids(rast)).* from fb_population_raster ) z
    group by 1
);