-- Create table with boundaries of polygons from prescale to osm
drop table if exists prescale_to_osm_boundaries;
create table prescale_to_osm_boundaries as (
    select ST_Transform(geog::geometry, 4326) as geom,
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
    from osm
    where ST_Dimension(geog::geometry) = 2
      and tags ? 'population'
      and tags ->> 'admin_level' is not null
      and osm_id in (select osm_id from prescale_to_osm)
    order by 1
);

-- Insert all boundaries, which are included in goal polygons
insert into table prescale_to_osm_boundaries (geom, osm_type, osm_id, population, admin_level)
    select ST_Transform(o.geog::geometry, 4326) as geom,
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
    from osm o 
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