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
set use = 'kindergarten'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'kindergarten'
  and use is null;

update osm_buildings_minsk b
set use = 'bank'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'bank'
  and use is null;

update osm_buildings_minsk b
set use = 'school'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'school'
  and use is null;

update osm_buildings_minsk b
set use = 'driving_school'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'driving_school'
  and use is null;

update osm_buildings_minsk b
set use = 'college'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'college'
  and use is null;

update osm_buildings_minsk b
set use = 'university'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'university'
  and use is null;

update osm_buildings_minsk b
set use = 'cinema'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'cinema'
  and use is null;

update osm_buildings_minsk b
set use = 'theatre'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'theatre'
  and use is null;

update osm_buildings_minsk b
set use = 'marketplace'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'marketplace'
  and use is null;

update osm_buildings_minsk b
set use = 'clinic'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'clinic'
  and use is null;

update osm_buildings_minsk b
set use = 'hospital'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'hospital'
  and use is null;

update osm_buildings_minsk b
set use = 'bus_station'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'bus_station'
  and use is null;

update osm_buildings_minsk b
set use = 'fuel'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity = 'fuel'
  and use is null;

update osm_buildings_minsk b
set use = 'garages'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse = 'garages'
  and use is null;

update osm_buildings_minsk b
set use = 'commercial'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse = 'commercial'
  and use is null;

update osm_buildings_minsk b
set use = 'industrial'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse = 'industrial'
  and use is null;

update osm_buildings_minsk b
set use = 'residential'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse = 'residential'
  and use is null;