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

update osm_buildings_minsk b
set use = amenity
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity in
      ('school', 'kindergarten', 'college', 'university', 'cinema', 'theatre', 'marketplace', 'hospital', 'clinic')
  and use is null;

update osm_buildings_minsk b
set use = landuse
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse in ('garage', 'retail', 'commercial', 'industrial', 'construction', 'military', 'railway', 'service')
  and use is null;

update osm_buildings_minsk b
set use = 'house'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse = 'residential'
  and o.residential = 'rural'
  and use is null;

update osm_buildings_minsk b
set use = 'apartments'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse = 'residential'
  and o.residential = 'urban'
  and use is null;

update osm_buildings_minsk
set use = 'house'
where building = 'house'
and use is null;

update osm_buildings_minsk
set use = 'apartments'
where building = 'apartments'
and use is null;
