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

update osm_buildings_minsk
set use = building
where building in
      ('apartments', 'cathedral', 'chapel', 'church', 'civic', 'clinic', 'college', 'commercial', 'construction',
       'dormitory', 'fire_station', 'garages', 'government', 'greenhouse', 'hospital', 'hotel', 'house', 'kindergarten',
       'kiosk', 'office', 'parking', 'prison', 'public', 'residential', 'retail', 'school', 'service', 'sports_centre',
       'sports_hall', 'stadium', 'train_station', 'transportation', 'university')
  and use is null;

update osm_buildings_minsk
set use = 'industrial'
where building in ('factory', 'warehouse', 'hangar', 'industrial')
  and use is null;

update osm_buildings_minsk b
set use = 'garages'
where building = 'garage'
  and use is null;

update osm_buildings_minsk b
set use = landuse
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.landuse in
      ('garages', 'retail', 'commercial', 'industrial', 'construction', 'military', 'railway', 'service', 'allotments',
       'railway', 'religious', 'brownfield')
  and use is null;

update osm_buildings_minsk b
set use = amenity
from osm_landuses_minsk o
where ST_Intersects(o.geom, b.geom)
  and o.amenity in
      ('bank', 'bus_station', 'cafe', 'car_wash', 'casino', 'childcare', 'cinema', 'clinic', 'college',
       'community_centre', 'courthouse', 'dentist', 'driving_school', 'embassy', 'fast_food',
       'fire_station', 'fire_station', 'fuel', 'hospital', 'kindergarten', 'library', 'marketplace', 'nightclub',
       'parking', 'place_of_worship', 'planetarium', 'police', 'police', 'prison', 'prison', 'pub', 'recycling',
       'register_office', 'restaurant', 'school', 'social_facility', 'studio', 'theatre', 'toilets', 'townhall',
       'tram_station', 'university')
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

delete from osm_buildings_minsk
where building = 'no';
