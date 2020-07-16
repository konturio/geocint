drop table if exists osm_population_raw;
create table osm_population_raw as (
    select ST_Transform(geog::geometry, 3857) as geom,
           osm_type,
           osm_id,
           ST_Area(geog)                      as area,
           (case
<<<<<<< HEAD
=======
               -- TODO: validator for values
>>>>>>> 155c37613b4e5e9e9d2298b14144f3df0af6c6b5
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
<<<<<<< HEAD
           (case
                when (tags ->> 'admin_level') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                    then (tags ->> 'population')::float
=======
           -- TODO: validator for non-numerics
           (case
                when (tags ->> 'admin_level') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
                    then (tags ->> 'admin_level')::float
>>>>>>> 155c37613b4e5e9e9d2298b14144f3df0af6c6b5
                else null
               end)                           as admin_level
    from osm
    where
<<<<<<< HEAD
        ST_Dimension(geog::geometry) = 2
      and tags ? 'population'
    and tags ->> 'admin_level' is not null
    order by 1
);
=======
      -- TODO: validator for lines and points
        ST_Dimension(geog::geometry) = 2
      and tags ? 'population'
      -- TODO: handle null admin level
      and tags ->> 'admin_level' is not null
    order by 1
);

>>>>>>> 155c37613b4e5e9e9d2298b14144f3df0af6c6b5
create index on osm_population_raw using gist (geom);
create index on osm_population_raw using gist (ST_PointOnSurface(geom));
