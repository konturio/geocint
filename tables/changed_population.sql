-- Add actual osm population column
alter table if exists prescale_to_osm
add column if not exists actual_pop bigint;

-- Update prescale_to osm with actual population data
update prescale_to_osm
	set actual_pop = o.tags ->> 'population'
	from osm o
	where prescale_to_osm.osm_id = o.ism_id;

-- Move changed objects from prescale to osm to new table for recheck
drop table if exists changed_population;
create table changed_population (osm_type text, osm_id bigint, name text, right_population bigint, change_date date, actual_pop bigint);

with changes as (
	delete 
		from prescale_to_osm 
		where right_population <> actual_pop
		returning osm_type, osm_id, name, right_population, change_date, actual_pop
)

insert into changed_population (osm_type, osm_id, name, right_population, change_date, actual_pop) select * from changes;