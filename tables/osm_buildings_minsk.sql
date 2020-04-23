drop table if exists osm_buildings_minsk;

create table osm_buildings_minsk as (
    select *
    from osm_buildings
    where ST_DWithin(
                  osm_buildings.geom,
                  (
                      select geog::geometry
                      from osm
                      where tags @> '{"name":"Минск", "boundary":"administrative"}'
                        and osm_id = 59195
                        and osm_type = 'relation'
                  ),
                  0
              )
);

create index on osm_buildings_minsk using gist (geom);

update osm_buildings_minsk b
set use = amenity
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity in ('school', 'kindergarten', 'college', 'university', 'cinema', 'theatre', 'marketplace', 'hospital', 'clinic', 'fuel')
  and use is null;

update osm_buildings_minsk b
set use = 'house'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse = '{"residential":"rural"}'
  and use is null;

update osm_buildings_minsk b
set use = 'apartments'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse = '{"residential":"urban"}'
  and use is null;

update osm_buildings_minsk b
set use = landuse
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse in ('garages', 'retail', 'commercial', 'industrial')
  and use is null;