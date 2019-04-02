drop table if exists osm_quality_grid_with_population;
create temporary table osm_quality_grid_with_population as (
    select
        coalesce(a.geom, b.geom)                                                          as geom,
        coalesce(count, 0)                                                                as count,
        coalesce(building_count, 0)                                                       as building_count,
        coalesce(highway_count, 0)                                                        as highway_count,
        coalesce(highway_length, 0)                                                       as highway_length,
        coalesce(amenity_count, 0)                                                        as amenity_count,
        coalesce(natural_count, 0)                                                        as natural_count,
        coalesce(landuse_count, 0)                                                        as landuse_count,
        coalesce(population, 0)                                                           as population,
        ST_Area(ST_Transform(coalesce(a.geom, b.geom), 4326)::geography)::float / 1000000 as area_km2
    from
        osm_object_count_grid_1000 a
            full outer join ghs_population_grid_1000 b on a.geom::bytea = b.geom::bytea
    order by 1
);

create index on osm_quality_grid_with_population using brin (geom);

drop table if exists osm_pop_stats;
create temporary table osm_pop_stats as (
    select
        percentile_cont(0.33333) within group (order by count / area_km2)      as count_ab,
        percentile_cont(0.66666) within group (order by count / area_km2)      as count_bc,
        1::float                                                               as population_12,
        percentile_cont(0.66666) within group (order by population / area_km2) as population_23
    from
        osm_quality_grid_with_population
    where
          population > 0
      and count > 0
);
analyse osm_pop_stats;


-- here we follow this idea:
-- http://www.joshuastevens.net/cartography/make-a-bivariate-choropleth-map/
-- A - less map objects than 33 percentile
-- B - intermediate map objects (33-66 percentile)
-- C - many objects (66+ percentile)
-- 1 - population less than 1 person on this square km
-- 2 - population less than 66 percentile
-- 3 - populated, more than 66 percentile.
-- A1 is not interesting for HOT, A3 needs mapping
drop table if exists osm_quality_bivariate_grid_1000;
create table osm_quality_bivariate_grid_1000 as (
    select
        geom,
        population,
        count,
        case
            when (count / area_km2) <= count_ab then 'A'
            when (count / area_km2) <= count_bc then 'B'
            else 'C' end ||
        case
            when (population / area_km2) <= population_12 then '1'
            when (population / area_km2) <= population_23 then '2'
            else '3' end as bivariate_class
    from
        osm_pop_stats,
        osm_quality_grid_with_population qg
);
create index on osm_quality_bivariate using brin (geom);