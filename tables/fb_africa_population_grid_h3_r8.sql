alter table fb_africa_population_raster
    set (parallel_workers = 32);

create table fb_africa_population_grid_h3_r8 as (
    select
        h3,
        8 as resolution,
        sum(sum) as population
    from
        ( select (h3_raster_sum_to_h3(rast, 8)).* from fb_africa_population_raster ) z
    group by 1
);