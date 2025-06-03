drop table if exists :population_raster_grid_h3;
create table :population_raster_grid_h3 as (
    select h3,
           sum(value) as population,
           :res       as resolution           
    from (select (h3_raster_agg_to_h3(rast, :res)).* from :population_raster) z
    group by 1
);