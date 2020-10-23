drop table if exists osm_population_raw;
create table osm_population_raw as (
    select ST_Transform(geog::geometry, 4326) as geom,
           osm_type,
           osm_id,
           ST_Area(geog)                      as area,
           (case
                when (tags ->> 'population') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                    then (tags ->> 'population')::float
                else null
               end)                           as population,
           1000000
               * (case
                      when (tags ->> 'population') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                          then (tags ->> 'population')::float
                      else null
               end) / ST_Area(geog)           as people_per_sq_km,
           (case
                when (tags ->> 'admin_level') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                    then (tags ->> 'admin_level')::float
                else null
               end)                           as admin_level
    from osm
    where ST_Dimension(geog::geometry) = 2
      and tags ? 'population'
      and tags ->> 'admin_level' is not null
    order by 1
);

create index on osm_population_raw using gist (geom);
create index on osm_population_raw using gist (ST_PointOnSurface(geom));
