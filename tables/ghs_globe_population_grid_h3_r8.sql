alter table ghs_globe_population_raster
    set (parallel_workers = 32);

drop table if exists ghs_globe_population_grid_h3_r8;
create table ghs_globe_population_grid_h3_r8 as (
    select
        h3,
        8 as resolution,
        sum(sum) as population
    from
        ( select (h3_raster_sum_to_h3(rast, 8)).* from ghs_globe_population_raster ) z
    group by 1
);

delete from ghs_globe_population_grid_h3_r8 where population=0;