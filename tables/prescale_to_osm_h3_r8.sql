-- Add column with population divided into hexs
alter table if exists prescale_to_osm_boundaries
add column if not exists divided_population int;

-- Update table and set population divided into hexs
with prep as (
    select distinct on (h3)
                        osm_id            as id
                        h3_polyfill(geom) as h3
)
with prep_mid as (
    select osm_id    as osm_id,
           count(*)  as hexs_number
    group by osm_id
)
update prescale_to_osm_boundaries
	set divided_population = population/hexs_number;


-- Get all hexs on 8 resolution, which cowered prescale_to_osm_boundaries
drop table if exists prescale_to_osm_h3_r8;
create table prescale_to_osm_h3_r8 as (
    select distinct on (h3)
           8                   as resolution, 
           osm_id              as osm_id,
           h3_polyfill(geom)   as h3
           divided_population  as population
    from prescale_to_osm_boundaries
);

drop table if exists prescale_to_osm_boundaries;