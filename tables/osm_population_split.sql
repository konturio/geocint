drop table if exists osm_population_split;
create table osm_population_split as (
  select
    ST_Subdivide(geom, 100) as geom,
    people_per_sq_km,
    null::float             as area
  from
    osm_population_raw
  where
    people_per_sq_km > 0
);
update osm_population_split set area = ST_Area(ST_Transform(geom, 4326)::geography) where area is null;
create index on osm_population_split using gist (geom);