drop table if exists ghs_population_grid_1000;
create table ghs_population_grid_1000 as (
  select
    ST_Expand(ST_SnapToGrid(centroid, 1000), 500) as geom,
    sum(people)                                   as population
  from
    ghs_globe_population_vector
  group by 1
  order by 1
);