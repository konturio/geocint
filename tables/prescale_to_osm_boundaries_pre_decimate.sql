-- Transform Water polygons to 4326
drop table if exists water_polygons_vector_4326;
create table water_polygons_vector_4326 as (
    select ST_Transform(geom, 4326) as geom 
    from water_polygons_vector
);

create index on water_polygons_vector_4326 using gist(geom);

-- Create temporary table with geometry and population from osm
drop table if exists prescale_to_osm_geom_in;
create table prescale_to_osm_geom_in as (
    select p.osm_id                                as osm_id, 
           o.osm_type                              as osm_type,
           cast(o.tags ->> 'population' as bigint) as actual_osm_pop,
           ST_Normalize(o.geog::geometry)          as geom
    from osm o,
         prescale_to_osm p
    where o.osm_id = p.osm_id and o.osm_type=p.osm_type
);

-- Create table with Water Area polygons for clipping
drop table if exists water_area_4326;
create table water_area_4326 as ( 
    select  p.osm_id           as osm_id,
            ST_Union(w.geom) as geom
    from prescale_to_osm_geom_in p,
         water_polygons_vector_4326 w
    where ST_Intersects(p.geom, w.geom)
    group by 1
);

drop table if exists prescale_to_osm_boundaries_in;
create table prescale_to_osm_boundaries_in as (
    select p.osm_type                                                as osm_type,
           p.osm_id                                                  as osm_id, 
           p.name                                                    as name,
           p.right_population                                        as right_population,
           coalesce(ST_Multi(ST_Difference(g.geom, w.geom)), g.geom) as geom,
           g.actual_osm_pop                                          as actual_osm_pop
    from prescale_to_osm_geom_in g,
         prescale_to_osm p,
         water_area_4326 w
    where g.osm_id = p.osm_id 
          and g.osm_type = w.osm_type          
);

drop table if exists prescale_to_osm_geom_in;
drop table if exists water_area_4326;
drop table if exists water_polygons_vector_4326;

-- Create table for storing cases with population that is different with last osm dump
-- Also for cases wiht null geometry
-- Move cases with outdated population and null-geometry objects to new table for recheck
drop table if exists changed_population;
create table changed_population as (
    with changes as (
        select * 
            from prescale_to_osm_boundaries_in 
            where right_population <> actual_osm_pop
            or geom is null
    )
    select * from changes
);

create index on prescale_to_osm_boundaries_in using gist(geom);

-- Create table with boundaries of polygons from prescale to osm
-- Get boundaries with admin_level for objects from prescale_to_osm
drop table if exists prescale_to_osm_boundaries_pre_decimate;
create table prescale_to_osm_boundaries_pre_decimate as (
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
            join prescale_to_osm_boundaries_in  as p
            on o.osm_id = p.osm_id
            where p.geom is not null
    )
    select  ST_Intersection(o.geom, p.geom)                                           as geom,
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
        and tags ? 'population'
        and tags ->> 'population' is not null
    union all
    select * from prep
);