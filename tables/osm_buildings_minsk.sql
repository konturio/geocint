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
  and o.landuse in
      ('garages', 'retail', 'commercial', 'industrial', 'construction', 'military', 'railway', 'service', 'allotments',
       'railway')
  and use is null;

update osm_buildings_minsk b
set use = tourism
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and tourism = 'museum'
  and use is null;

update osm_buildings_minsk b
set use = leisure
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and leisure = 'sports_centre'
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

update osm_buildings_minsk b
set use = 'residential'
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse = 'residential'
  and use is null;

update osm_buildings_minsk
set use = building
where building in ('apartments', 'public', 'retail', 'house', 'sports_hall', 'stadium', 'parking', 'office', 'garages',
                   '"greenhouse"', 'transportation', 'dormitory', 'government', 'hotel', 'hospital', 'school',
                   'university', 'commercial', 'church', 'sports_centre', 'prison', 'train_station', 'residential',
                   'college', 'construction', 'service')
  and use is null;

update osm_buildings_minsk
set use = 'industrial'
where building in ('factory', 'warehouse', 'hangar')
  and use is null;
