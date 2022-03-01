-- Add actual osm population column
alter table if exists prescale_to_osm
add column if not exists actual_pop bigint,
add column if not exists geom geometry(POLYGON, 4326);

-- Update prescale_to osm with actual population data
update prescale_to_osm
	set actual_pop = o.tags ->> 'population',
	set geom = ST_Transform(geog::geometry, 4326)
	from osm o
	where prescale_to_osm.osm_id = o.ism_id;

drop table if exists changed_population;
create table changed_population (osm_type text, 
	                             osm_id bigint, 
	                             name text, 
	                             right_population bigint, 
	                             change_date date, 
	                             actual_pop bigint, 
	                             geom geometry(POLYGON, 4326));

-- Move changed and null-geometry objects from prescale to osm to new table for recheck
with changes as (
	delete 
		from prescale_to_osm 
		where right_population <> actual_pop
		or geom is null
		returning osm_type, osm_id, name, right_population, change_date, actual_pop, geom
)


insert into changed_population (osm_type, 
	                            osm_id, 
	                            name, 
	                            right_population, 
	                            change_date, 
	                            actual_pop, 
	                            geom) 
	select * 
	from changes;
