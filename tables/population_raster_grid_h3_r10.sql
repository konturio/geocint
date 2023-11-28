
drop table if exists :population_raster_grid_h3_r10;
create table :population_raster_grid_h3_r10 as (
    select h3,
           10        as resolution,
           sum(sum)  as population
    from (select (h3_raster_sum_to_h3(rast, 10)).* from :population_raster) z
    group by 1
);
