drop table if exists osm_population_split;
create table osm_population_split as (
  select
    ST_Subdivide(geom, 100) as geom,
    people_per_sq_km,
    null::float             as area
  from
    -- TODO: fix after https://trac.osgeo.org/postgis/ticket/4459#ticket
    (select (ST_Dump(geom)).geom, people_per_sq_km from osm_population_raw) z
  where
    people_per_sq_km > 0 
    -- TODO: remove after https://trac.osgeo.org/postgis/ticket/4459#ticket is done
    and not ST_IsEmpty(geom)
    order by 1
);
update osm_population_split set area = ST_Area(ST_Transform(geom, 4326)::geography) where area is null;
vacuum osm_population_split;
create index on osm_population_split using gist (geom);
