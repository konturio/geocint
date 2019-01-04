drop table if exists osm_hospitals;
explain create table osm_hospitals as (
  select
    way            as geom,
    tags -> 'name' as name
  from
    planet_osm_point
  where
    tags ? 'amenity'
    and (tags -> 'amenity') = 'hospital'
  order by 1
);