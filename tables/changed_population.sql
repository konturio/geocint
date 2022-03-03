-- Update prescale_to osm with actual population data
update prescale_to_osm
	set actual_osm_pop = o.tags ->> 'population',
	set geom = o.geom
	from osm_admin_boundaries o
	where prescale_to_osm.osm_id = o.osm_id;

-- Create table for storing cases with population that is different with last osm dump
-- Also for cases wiht null geometry
drop table if exists changed_population;
create table changed_population (osm_type text, 
	                             osm_id bigint, 
	                             name text, 
	                             right_population bigint, 
	                             change_date date, 
	                             actual_osm_pop bigint, 
	                             geom geometry(geometry, 4326));

-- Move cases with outdated population and null-geometry objects to new table for recheck
with changes as (
	delete 
		from prescale_to_osm 
		where right_population <> actual_osm_pop
		or geom is null
		returning osm_type, osm_id, name, right_population, change_date, actual_osm_pop, geom
)


insert into changed_population (osm_type, 
	                            osm_id, 
	                            name, 
	                            right_population, 
	                            change_date, 
	                            actual_osm_pop, 
	                            geom) 
	select * 
	from changes;

create index on prescale_to_osm using gist(geom);