-- union all population and building h3 hexagon tables
drop table if exists kontur_population_in;
create table kontur_population_in as (
    select h3,
           false                            as probably_unpopulated,
           coalesce(max(building_count), 0) as building_count,
           coalesce(max(population), 0)     as population

    from (
             select h3,
                    building_count as building_count,
                    null::float    as population
             from building_count_grid_h3
             where resolution = 8
             union all
             select h3,
                    null::float as building_count,
                    population  as population
             from population_grid_h3_r8
             where population > 0
             order by 1
         ) z
    group by 1
);


-- generate geometries and areas for hexagons
drop table if exists kontur_population_mid1;
create table kontur_population_mid1 as (
    select a.*,
           hex.area / 1000000.0 as area_km2,
           hex.geom             as geom
    from kontur_population_in a
             join ST_HexagonFromH3(h3) hex on true
);

create index on kontur_population_mid1 using brin (geom);

drop table kontur_population_in;