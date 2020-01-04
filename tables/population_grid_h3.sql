drop table if exists population_grid_h3;
create table population_grid_h3 as (
    select resolution,
           h3,
           sum(people) as population
    from population_vector,
         ST_H3Bucket(geom) as hex
    group by 1, 2
    order by 1, 2

);
