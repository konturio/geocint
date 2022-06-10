-- Transform prescale_to_osm_boundaries table to 3857
drop table if exists prescale_to_osm_boundaries_3857;
create table prescale_to_osm_boundaries_3857 as 
        select ST_Transform(geom, 3857) as geom,
               osm_id,
               population
        from prescale_to_osm_boundaries;

drop table if exists prescale_to_osm_boundaries;

-- Calculate Kontur population for each boundary
-- Also calculate scaled coefficient for population
drop table if exists prescale_to_osm_coefficient_table;
create table prescale_to_osm_coefficient_table as
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
        from prescale_to_osm_boundaries_3857 b
        join kontur_population_h3 h
                on ST_Intersects(h.geom, b.geom)
                        and h.resolution = 8
                        and h.population > 0
        group by 1
)
select
        b.geom,
        b.osm_id,
        b.population::float / p.population::float as coefficient
from prescale_to_osm_boundaries_3857 b
left join sum_population p using(osm_id);

create index on prescale_to_osm_coefficient_table using gist(geom);

drop table if exists prescale_to_osm_boundaries_3857;