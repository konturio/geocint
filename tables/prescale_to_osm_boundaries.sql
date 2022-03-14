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

-- Get boundaries with admin_level for objects from prescale_to_osm
with prep as (select p.geom,
                     p.osm_id, 
                     p.admin_level,
                     p.tags
                  from osm_admin_boundaries as o
                  join prescale_to_osm  as p
                  on o.osm_id = p.osm_id)
-- Create CTE which include all boundaries from prep and low-level boundaries that them include
with prep_mid as (select o.geom,
                         o.osm_id, 
                         o.admin_level,
                         o.tags
                      from osm_admin_boundaries o 
                      join prep p
                      on ST_Intersects(p.geom, ST_PointOnSurface(o.geom))
                      where o.admin_level > p.admin_level
                  union all
                  select * 
                      from prep
)

create table prescale_to_osm_boundaries as
    select  geom,
            osm_type,
            osm_id, 
            (case
                 when (tags ->> 'population') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                     then (tags ->> 'population')::float
                 else null
            end)                               as population,
            (case
                 when (tags ->> 'admin_level') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                     then (tags ->> 'admin_level')::float
                 else null
            end)                               as admin_level
            from prep_mid
            where ST_Dimension(geom) = 2
                  and tags ? 'population'
                  and tags ->> 'admin_level' is not null
            order by 1;

create index on prescale_to_osm_boundaries using gist (geom);
create index on prescale_to_osm_boundaries using gist (ST_PointOnSurface(geom));

drop table if exists prescale_to_osm;