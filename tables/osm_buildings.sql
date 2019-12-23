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

update population_vector_constrained p
  set min_population = (select count(b.*) from osm_building b where ST_Intersects(p.geom, b.geom));

-- TODO: count duplicates
insert into population_vector_constrained(centroid, geom, people, min_population) 
  select a.geom, ST_Expand(ST_SnapToGrid(a.geom, 15, 15), 7.5), null, 1 from osm_buildings a where not exists(select 1 from population_vector_constrained b where ST_Intersects(a.geom, b.geom));

vacuum population_vector_constrained;
