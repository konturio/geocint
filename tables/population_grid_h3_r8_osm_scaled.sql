-- Create subdivided prescale_to_osm_boundaries
drop table if exists prescale_to_osm_boundaries_subdivide;
create table prescale_to_osm_boundaries_subdivide as (
        select ST_Subdivide(geom, 100) geom,
               osm_id,
               population
        from prescale_to_osm_boundaries
);

create index on prescale_to_osm_boundaries_subdivide using gist(geom);

-- Calculate Kontur population for each boundary
drop table if exists prescale_to_osm_boundary_with_population;
create table prescale_to_osm_boundary_with_population as (
        with sum_population as (
                select
                        b.osm_id,
                        -- Calculate kontur population for each boundary from prescale table
                        -- We need for '+1' in the end to make sure special case of 
                        --"population sum in all hexagons was 0 but has to be not 0" is handled.               
                        coalesce(round(sum(h.population)), 0) + 1 as population
                from prescale_to_osm_boundaries_subdivide b
                join population_grid_h3_r8 h
                        on ST_Intersects(h.geom, b.geom)
                                and h.population > 0
                group by 1
)
        select
                b.geom,
                b.osm_id,
                b.population      as boundary_population, 
                sum(p.population) as grid_population
        from prescale_to_osm_boundaries b
        left join sum_population p using(osm_id)
        group by 1, 2, 3
);

drop table if exists prescale_to_osm_boundaries_subdivide;

-- Create subdivide coefficient table
drop table if exists prescale_to_osm_coefficient_table_subdivide;
create table prescale_to_osm_coefficient_table_subdivide as (
        select ST_Subdivide(geom, 100) as geom,
               osm_id,
               boundary_population::float / grid_population::float as coefficient
        from prescale_to_osm_boundary_with_population
);

create index on prescale_to_osm_coefficient_table_subdivide using gist(geom);

-- scale to 0 building count for hexes that should have population 0 after scaling
drop table if exists building_count_grid_h3_scaled_in;
create table building_count_grid_h3_scaled_in as (
    select h3,
           h3::geometry              as geom,
           resolution                as resolution,
           building_count            as building_count
    from building_count_grid_h3
    where resolution = 8);

-- Scale building_count_grid_h3_scaled_in 
drop table if exists building_count_grid_h3_scaled_mid;
create table building_count_grid_h3_scaled_mid as (
        select p.h3,
               p.resolution,
               p.building_count * b.coefficient as building_count             
        from building_count_grid_h3_scaled_in p,
             prescale_to_osm_coefficient_table_subdivide b
        where ST_Intersects(b.geom, p.geom) and b.coefficient = 0);

-- Combine scaled and raw data to final building count grid 
drop table if exists building_count_grid_h3_scaled;
create table building_count_grid_h3_scaled as (
        select h3,
               resolution,
               building_count,
               true as is_scaled             
        from building_count_grid_h3_scaled_mid
        union all
        select h3,
               resolution,
               building_count,
               null::boolean as is_scaled
        from building_count_grid_h3_scaled_in
        where h3 not in (select h3 from building_count_grid_h3_scaled_mid)
);

drop table if exists building_count_grid_h3_scaled_in;
drop table if exists building_count_grid_h3_scaled_mid;

create index on building_count_grid_h3_scaled using brin (h3);

-- Scale population_grid_h3_r8 
drop table if exists population_grid_h3_r8_osm_scaled_in;
create table population_grid_h3_r8_osm_scaled_in as (
        select p.h3,
               p.geom,
               p.resolution,
               p.population * b.coefficient as population,
               p.ghs_pop,
               p.hrsl_pop               
        from population_grid_h3_r8 p,
             prescale_to_osm_coefficient_table_subdivide b
        where ST_Intersects(b.geom, p.geom)
);

drop table if exists prescale_to_osm_coefficient_table_subdivide;
create index on population_grid_h3_r8_osm_scaled_in using btree (h3);

-- Combine scaled and raw data to final population grid
drop table if exists population_grid_h3_r8_osm_scaled;
create table population_grid_h3_r8_osm_scaled as (
        select p.h3,
               p.geom,
               p.resolution,
               p.population,
               p.ghs_pop,
               p.hrsl_pop,
               null::boolean as is_scaled
        from population_grid_h3_r8 p
        where h3 not in (select h3 from population_grid_h3_r8_osm_scaled_in)
        union all
        select distinct p.h3,
                        p.geom,
                        p.resolution,
                        p.population,
                        p.ghs_pop,
                        p.hrsl_pop,
                        true as is_scaled
        from population_grid_h3_r8_osm_scaled_in p
);

create index on population_grid_h3_r8_osm_scaled using gist (geom, population);