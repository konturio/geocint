drop table if exists osm_hospitals;
create table osm_hospitals as (
    select osm_id,
           tags,
           ST_Centroid(geog::geometry) as geom
    from osm o
    where tags ? 'amenity'
      and tags ->> 'amenity' = 'hospital'
);
create index on osm_hospitals using gist(geom);
