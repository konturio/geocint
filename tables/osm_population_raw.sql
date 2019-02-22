drop table if exists osm_population_raw;
create table osm_population_raw as (
  select
    ST_Transform(geog::geometry, 3857) as geom,
    osm_type,
    osm_id,
    ST_Area(geog)                      as area,
    (case
      -- TODO: validator for values
       when (tags ->> 'population') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$' then CAST((tags ->> 'population') as FLOAT)
       else null
      end)                             as population,
    1000000
      * (case
           when (tags ->> 'population') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$'
             then CAST((tags ->> 'population') as FLOAT)
           else null
      end) / ST_Area(geog)             as people_per_sq_km,
    -- TODO: validator for non-numerics
    (case
       when (tags ->> 'admin_level') ~ E'^[[:digit:]]+([.][[:digit:]]+)?$' then CAST((tags ->> 'admin_level') as FLOAT)
       else null
      end)                             as admin_level
  from
    osm
  where
    -- TODO: handle points by looking for sirrounding polygon and/or building a voronoi diagram within some admin level
    ST_GeometryType(geog::geometry) != 'ST_Point'
    -- TODO: validator for population-lines
    and ST_GeometryType(geog::geometry) != 'ST_LineString'
    and tags ? 'population'
  order by 1
);
-- TODO: handle null admin level
delete from osm_population_raw where admin_level is null;
create index on osm_population_raw using gist (geom);
create index on osm_population_raw using gist (ST_PointOnSurface(geom));