drop table if exists population_grid_h3_r8;
create table population_grid_h3_r8 as (
    select
        8 as resolution,
        h3_geo_to_h3(ST_Transform(centroid, 4326)::point, 8) as h3,
        sum(people) as population
    from
        population_vector
    group by 2
);
