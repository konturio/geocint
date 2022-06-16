-- Calculate Kontur population for each boundary
-- Also calculate scaled coefficient for population
drop table if exists prescale_to_osm_coefficient_table_in;
create table prescale_to_osm_coefficient_table_in as
with sum_population as (
        select
                b.osm_id,
                -- Calculate kontur population for each boundary from prescale table
                -- We need for '+1' in the end to make sure special case of 
                --"population sum in all hexagons was 0 but has to be not 0" is handled.               
                coalesce(round(sum(h.population * (case
                                               when ST_Within(h.geom, b.geom) then 1
                                               else ST_Area(ST_Intersection(h.geom, b.geom)) / ST_Area(h.geom)
                                          end))), 0) + 1 as population
        from prescale_to_osm_boundaries b
        join population_grid_h3_r8 h
                on ST_Intersects(h.geom, b.geom)
                        and h.population > 0
        group by 1
)
select
        b.geom,
        b.osm_id,
        b.population::float / p.population::float as coefficient
from prescale_to_osm_boundaries b
left join sum_population p using(osm_id);

drop table if exists prescale_to_osm_boundaries_3857;

-- Transform prescale_to_osm_coefficient_table_in table to 4326
drop table if exists prescale_to_osm_coefficient_table;
create table prescale_to_osm_coefficient_table as
        select ST_Transform(geom, 4326) as geom,
               osm_id,
               coefficient
        from prescale_to_osm_coefficient_table_in;

drop table if exists prescale_to_osm_coefficient_table_in;
create index on prescale_to_osm_coefficient_table using gist(geom);

-- Prescale population to osm using coefficient
update population_grid_h3_r8 p
set population = p.population * b.coefficient
from prescale_to_osm_coefficient_table b
where ST_Intersects(b.geom, p.geom);