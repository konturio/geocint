drop table if exists osm_quality_bivariate_grid_h3_meta;
create table osm_quality_bivariate_grid_h3_meta as (
    select
        2::float as count_ab,
        round(percentile_cont(0.75) within group (order by count / area_km2)) as count_bc,
        ceil(max(count / area_km2)) as count_max,
        2::float as population_12,
        round(percentile_cont(0.75) within group (order by population / area_km2)) as population_23,
        ceil(max(population / area_km2)) as population_max
    from
        stat_h3
    where
          population > 0
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
    select
        geom,
        population,
        count,
        area_km2,
        zoom,
        case
            when (count / area_km2) <= count_ab then 'A'
            when (count / area_km2) <= count_bc then 'B'
            else 'C'
        end ||
        case
            when (population / area_km2) <= population_12 then '1'
            when (population / area_km2) <= population_23 then '2'
            else '3'
        end as bivariate_class
    from
        osm_quality_bivariate_grid_h3_meta,
        stat_h3 qg
    where
         population > 0
      or count > 0
);
create index on osm_quality_bivariate_grid_h3 using gist (geom, zoom);
