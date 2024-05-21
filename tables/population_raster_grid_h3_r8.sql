drop table if exists :population_raster_grid_h3_r8;
create table :population_raster_grid_h3_r8 as (
    select h3,
           8          as resolution,
           sum(value) as population
    from (select (h3_raster_agg_to_h3(rast, 8, 'sum')).* from :population_raster) z
    group by 1
);
