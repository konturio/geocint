drop table if exists :population_raster_grid_h3_r11;
create table :population_raster_grid_h3_r11 as (
    select h3,
           sum(value)  as population,
           11          as resolution
    from (select (h3_raster_agg_to_h3(rast, 11)).* from :population_raster) z
    group by 1
);
