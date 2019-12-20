drop table if exists osm_building;

create table osm_building as (
  select
    osm_type,
    osm_id,
    ST_Transform(ST_PointOnSurface(geog::geometry), 3857) as geom
  from
    osm
  where
    ((tags ->> 'building') is not null)
);

create index on osm_building using gist(geom);

alter table population_vector add column min_population float;

update population_vector p
  set min_population = (select count(b.*) from osm_building b where ST_Intersects(p.geom, b.geom));

insert into population_vector(centroid, geom, people, min_population) 
  select a.geom, ST_Expand(ST_SnapToGrid(a.geom, 15, 15), 7.5), null, 1 from osm_buildings a where not exists(select 1 from population_vector b where ST_Intersects(a.geom, b.geom));
