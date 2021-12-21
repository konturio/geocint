drop table if exists osm_fire_stations;
create table osm_fire_stations as (
    select osm_id,
           tags,
           ST_Centroid(geog::geometry) as geom
    from osm o
    where tags ? 'amenity'
      and tags ->> 'amenity' = 'fire_station'
);
create index on osm_fire_stations using gist(geom);
