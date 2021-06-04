insert into osm_buildings_london (building, street, hno, levels, height, use, "name", geom)
select building,
       street,
       hno,
       levels,
       height,
       use,
       "name",
       geom
from osm_buildings b
where ST_Dimension(geom) != 1
  and ST_DWithin(b.geom, (
    select geom
    from osm_admin_boundaries
    where osm_id = 51800
      and osm_type = 'relation'), 0);

insert into osm_boundary_london (id, name, geom)
select osm_id as id, name, geom
from osm_admin_boundaries
where osm_id = 51800
  and osm_type = 'relation';
