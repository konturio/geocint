create index on planet_osm_point using gist(tags);
create index on planet_osm_polygon using gist(tags);
create index on planet_osm_line using gist(tags);

create view osm as (
  select
    way as geom,
    tags as tags
  from
    planet_osm_point
  union all
  select
    way as geom,
    tags as tags
  from
    planet_osm_line
  union all
  select
    way as geom,
    tags as tags
  from
    planet_osm_polygon
);