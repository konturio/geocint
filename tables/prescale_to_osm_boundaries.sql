-- Transform Water polygons to 4326
drop table if exists water_polygons_vector_4326;
create table water_polygons_vector_4326 as (
    select ST_Transform(geom, 4326) as geom 
    from water_polygons_vector
);

create index on water_polygons_vector_4326 using gist(geom);

-- Create temporary table with geometry and population from osm
-- In this query we use osm table instead of osm_admin_boundaries
-- to be able to scale not only by admin boundaries
drop table if exists prescale_to_osm_boundaries_unclipped_in;
create table prescale_to_osm_boundaries_unclipped_in as (
    select p.osm_id                                as osm_id, 
           cast(o.tags ->> 'population' as bigint) as actual_osm_pop,
           p.right_population                      as right_population,
           null::integer                           as admin_level,
           ST_Normalize(o.geog::geometry)          as geom
    from osm o,
         prescale_to_osm p
    where o.osm_id = p.osm_id and o.osm_type=p.osm_type
);

-- Add polygon to scale sum popualtion in hexagons within 10km Chornobyl Nuclear Power Plant to 0,
-- nuclear station stuff to 300
-- and sum population in hexagons betwen 10 and 30 km within Chornobyl Nuclear Power Plant to 1500
-- last case is a palestinian territories that doesn't have a general border and we should use this
-- trick to be able to get right total
insert into prescale_to_osm_boundaries_unclipped_in  
    select  max(osm_id)+1                                                                           as osm_id,
            300                                                                                     as actual_osm_pop,
            300                                                                                     as right_population,
            23::integer                                                                             as admin_level,
            ST_Buffer(ST_SetSRID(ST_Point(30.0985005,51.3894223),4326)::geography, 10000)::geometry as geom
    from prescale_to_osm_boundaries_unclipped_in
    union all
    select  max(osm_id)+2                                                                           as osm_id,
            300                                                                                     as actual_osm_pop,
            300                                                                                     as right_population,
            24::integer                                                                             as admin_level,
            ST_Buffer(ST_SetSRID(ST_Point(30.0985005,51.3894223),4326)::geography, 1000)::geometry  as geom
    from prescale_to_osm_boundaries_unclipped_in
    union all
    select  osm_id                           as osm_id,
            1800                             as actual_osm_pop,
            1800                             as right_population,
            22::integer                      as admin_level,
            ST_Normalize(geog::geometry)     as geom
    from osm
    where osm_id = 3311547
    union all
    select  1703814                  as osm_id,
            5371230                  as actual_osm_pop,
            5371230                  as right_population,
            2::integer               as admin_level,
            b.geom                   as geom
        from (select ST_Union(ST_Normalize(geog::geometry)) as geom
                  from osm 
                  where osm_id in ('3791785','7391020','1703814') and osm_type = 'relation') b;

drop table if exists prescale_to_osm_boundaries_unclipped;
create table prescale_to_osm_boundaries_unclipped as (
    select p.osm_id,
           p.actual_osm_pop,
           p.right_population,
           coalesce(p.admin_level,o.kontur_admin_level,24) as admin_level,
           p.geom
    from prescale_to_osm_boundaries_unclipped_in as p 
         left join osm_admin_boundaries as o
         on o.osm_id = p.osm_id
);

create index on prescale_to_osm_boundaries_unclipped using gist(geom);
drop table if exists prescale_to_osm_boundaries_unclipped_in;

-- Create table with Water Area polygons for clipping
drop table if exists water_area_4326;
create table water_area_4326 as ( 
    select  p.osm_id         as osm_id,
            ST_Union(w.geom) as geom
    from prescale_to_osm_boundaries_unclipped p,
         water_polygons_vector_4326 w
    where ST_Intersects(p.geom, w.geom)
    group by 1
);

drop table if exists prescale_to_osm_boundaries_in;
create table prescale_to_osm_boundaries_in as (
    select  g.osm_id                                             as osm_id,
            g.actual_osm_pop                                     as actual_osm_pop,
            g.right_population                                   as right_population,
            g.admin_level                                        as admin_level,
            case 
                when w.osm_id is not null 
                    then ST_Multi(ST_Difference(g.geom, w.geom))
                else g.geom
            end                                                  as geom
    from prescale_to_osm_boundaries_unclipped g left join
         water_area_4326 w
    on g.osm_id = w.osm_id        
);

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
drop table if exists prescale_to_osm_boundaries;
create table prescale_to_osm_boundaries as (
    select  p.geom             as geom,
            p.osm_id           as osm_id, 
            p.right_population as population,
            p.admin_level      as admin_level,
            false              as isdeg,
            null::float        as pop_ulevel
        from prescale_to_osm_boundaries_in as p
);

create index on prescale_to_osm_boundaries using gist (geom, ST_PointOnSurface(geom));
