drop table if exists osm_quality_bivariate_grid_h3_meta;
create table osm_quality_bivariate_grid_h3_meta as (
    select 2::float                                                                   as count_ab,
           round(percentile_cont(0.75) within group (order by count / area_km2))      as count_bc,
           round(max(count / area_km2))                                               as count_max,
           2::float                                                                   as population_12,
           round(percentile_cont(0.75) within group (order by population / area_km2)) as population_23,
           round(max(population / area_km2))                                          as population_max
    from osm_object_count_grid_h3_with_population
    where population > 1
      and zoom = 6
);
analyse osm_quality_bivariate_grid_h3_meta;


-- here we follow this idea:
-- http://www.joshuastevens.net/cartography/make-a-bivariate-choropleth-map/
-- A - less map objects than 33 percentile
-- B - intermediate map objects (33-66 percentile)
-- C - many objects (66+ percentile)
-- 1 - population less than 1 person on this square km
-- 2 - population less than 66 percentile
-- 3 - populated, more than 66 percentile.
-- A1 is not interesting for HOT, A3 needs mapping
drop table if exists osm_quality_bivariate_grid_h3;
create table osm_quality_bivariate_grid_h3 as (
    select geom,
           population,
           count,
           area_km2,
           zoom,
           case
               when (count / area_km2) <= count_ab then 'A'
               when (count / area_km2) <= count_bc then 'B'
               else 'C' end ||
           case
               when (population / area_km2) <= population_12 then '1'
               when (population / area_km2) <= population_23 then '2'
               else '3' end as bivariate_class
    from osm_quality_bivariate_grid_h3_meta,
         osm_object_count_grid_h3_with_population qg
);
create index on osm_quality_bivariate_grid_h3 using gist (geom, zoom);
