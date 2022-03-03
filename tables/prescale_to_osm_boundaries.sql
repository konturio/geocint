-- Update prescale_to osm with actual population data
update prescale_to_osm
    set actual_osm_pop = o.tags ->> 'population',
    set geom = o.geom
    from osm_admin_boundaries o
    where prescale_to_osm.osm_id = o.osm_id;

-- Create table for storing cases with population that is different with last osm dump
-- Also for cases wiht null geometry
-- Move cases with outdated population and null-geometry objects to new table for recheck
drop table if exists changed_population;
with changes as (
    delete 
        from prescale_to_osm 
        where right_population <> actual_osm_pop
        or geom is null
        returning osm_type, osm_id, name, right_population, change_date, actual_osm_pop, geom
)

create table changed_population as 
    select * 
    from changes;

create index on prescale_to_osm using gist(geom);

-- Create table with boundaries of polygons from prescale to osm
drop table if exists prescale_to_osm_boundaries;
create table prescale_to_osm_boundaries as (
    select geom,
           osm_type,
           osm_id,
           (case
                when (tags ->> 'population') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                    then (tags ->> 'population')::float
                else null
               end)                           as population,
           (case
                when (tags ->> 'admin_level') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                    then (tags ->> 'admin_level')::float
                else null
               end)                           as admin_level
    from osm_admin_boundaries
    where ST_Dimension(geog::geometry) = 2
      and tags ? 'population'
      and tags ->> 'admin_level' is not null
      and osm_id in (select osm_id from prescale_to_osm)
    order by 1
);

-- Insert all boundaries, which are included in goal polygons
insert into table prescale_to_osm_boundaries (geom, osm_type, osm_id, population, admin_level)
    select o.geom,
           o.osm_type,
           o.osm_id,
           (case
                when (tags ->> 'population') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                    then (tags ->> 'population')::float
                else null
               end)                           as population,
           (case
                when (tags ->> 'admin_level') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                    then (tags ->> 'admin_level')::float
                else null
               end)                           as admin_level
    from osm_admin_boundaries o 
    left join prescale_to_osm_boundaries p
    on ST_Intersects(o.geom, p.geom)
    where ST_Dimension(o.geog::geometry) = 2
      and tags ? 'population'
      and tags ->> 'admin_level' is not null
      and tags ->> 'admin_level' < p.admin_level
    order by 1
);

create index on prescale_to_osm_boundaries using gist (geom);
create index on prescale_to_osm_boundaries using gist (ST_PointOnSurface(geom));

drop table if exists prescale_to_osm;