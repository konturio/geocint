-- Create table with hexs with population
-- We use this table in us_census_tracts_stats_h3
drop table if exists us_census_tracts_population_h3_r8;
create table us_census_tracts_population_h3_r8 as (
    select u.affgeoid,
           p.h3,
           p.population as population,
           p.geom
    from us_census_tract_boundaries_subdivide u,
         kontur_population_h3 p
    where ST_Intersects(u.geom, ST_PointOnSurface(ST_Transform(p.geom, 4326)))
          and p.resolution = 8
);