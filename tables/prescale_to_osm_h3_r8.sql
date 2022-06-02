-- Transform to 3857
drop table if exists prescale_to_osm_boundaries_3857;
create table prescale_to_osm_boundaries_3857 as 
        select ST_Transform(geom, 3857) as geom,
               osm_id,
               population
        from prescale_to_osm_boundaries;

drop table if exists prescale_to_osm_boundaries;

-- Calculate Kontur population for each boundary
drop table if exists prescale_to_osm_h3_r8;
create table prescale_to_osm_h3_r8 as
with sum_population as (
        select
                b.osm_id,

                 -- Calculate intersection area for each h3 cell and boundary polygon                 
                round(sum(h.population * (case
                                               when ST_Within(h.geom, b.geom) then 1
                                               else ST_Area(ST_Intersection(h.geom, b.geom)) / ST_Area(h.geom)
                                          end))) as population
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
        (case
             when p.population is not null and p.population > 0
                 then (b.population::float / p.population::float)
             else 1::float
        end)                as coefficient,
        b.admin_level
from prescale_to_osm_boundaries_3857 b
left join sum_population p using(osm_id);

create index on prescale_to_osm_h3_r8 using gist(geom);

drop table if exists prescale_to_osm_boundaries_3857;