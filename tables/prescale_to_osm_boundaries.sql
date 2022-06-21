-- Update prescale_to osm with actual population data
update prescale_to_osm
    set actual_osm_pop = cast(o.tags ->> 'population' as bigint),
        geom = ST_Normalize(o.geog::geometry)
    from osm o
    where prescale_to_osm.osm_id = o.osm_id;

-- Create table for storing cases with population that is different with last osm dump
-- Also for cases wiht null geometry
-- Move cases with outdated population and null-geometry objects to new table for recheck
drop table if exists changed_population;
create table changed_population as (
    with changes as (
        select * 
            from prescale_to_osm 
            where right_population <> actual_osm_pop
            or geom is null
    )
    select * from changes
);

create index on prescale_to_osm using gist(geom);

-- Create table with boundaries of polygons from prescale to osm
-- Get boundaries with admin_level for objects from prescale_to_osm
drop table if exists prescale_to_osm_boundaries;
create table prescale_to_osm_boundaries as (
    with prep as (
        select  p.geom                                                                    as geom,
                p.osm_id                                                                  as osm_id, 
                (case
                    when (tags ->> 'population') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                        then (tags ->> 'population')::float
                    else null
                end)                                                                      as population,
                o.kontur_admin_level                                                      as admin_level,
                false                                                                     as isdeg,
                null::float                                                               as pop_ulevel
            from osm_admin_boundaries as o
            join prescale_to_osm  as p
            on o.osm_id = p.osm_id
            where p.geom is not null
    )
    select  o.geom                                                                    as geom,
            o.osm_id                                                                  as osm_id, 
            (case
                when (tags ->> 'population') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                    then (tags ->> 'population')::float
                else null
            end)                                                                      as population,
            o.kontur_admin_level                                                      as admin_level,
            false                                                                     as isdeg,
            null::float                                                               as pop_ulevel
    from osm_admin_boundaries o 
    join prep p
        on ST_Intersects(p.geom, ST_PointOnSurface(o.geom))
        where o.kontur_admin_level > p.admin_level
    union all
    select * from prep
);

create index on prescale_to_osm_boundaries using gist (geom, ST_PointOnSurface(geom));