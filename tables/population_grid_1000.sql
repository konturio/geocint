drop table if exists population_grid_1000;
create table population_grid_1000 as (
    select
        ST_Pixel(geom, 7) as geom,
        sum(people)       as population
    from
        population_vector
    group by 1
    order by 1
);
