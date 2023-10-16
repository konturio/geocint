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
drop table if exists prescale_to_osm_coefficient_table;
create table prescale_to_osm_coefficient_table as (
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
        from prescale_to_osm_coefficient_table
);

create index on prescale_to_osm_coefficient_table_subdivide using gist(geom);

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
        select *
        from population_grid_h3_r8
        where h3 not in (select h3 from population_grid_h3_r8_osm_scaled_in)
        union all
        select distinct *
        from population_grid_h3_r8_osm_scaled_in p
);

create index on population_grid_h3_r8_osm_scaled using gist (geom, population);