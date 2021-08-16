-- NOTICE: there are no administrative boundaries of abu dhabi districts in osm. we use the boundaries from gadm
drop table if exists abu_dhabi_admin_boundaries;
create table abu_dhabi_admin_boundaries as (
    select g.gid, g.name, g.gadm_level, g.geom
    from gadm_boundaries g,
         osm o
    where o.tags @> '{"admin_level": "5"}' -- to use the index
      and o.osm_id = 4479763               -- osm_id of Abu-Dhabi boundary
      and o.osm_type = 'relation'          -- additional check of boundary type
      and ST_Intersects(o.geog::geometry, g.geom)
      and ST_Area(ST_Intersection(o.geog::geometry, g.geom)) / ST_Area(g.geom) > 0.5
);

