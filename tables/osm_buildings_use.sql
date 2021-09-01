drop index if exists osm_buildings_geom_idx_nulluse;
create index osm_buildings_geom_idx_nulluse on osm_buildings using gist (geom) where use is null;

update osm_buildings b
set use = case
              when amenity in
                   ('bank', 'bus_station', 'cafe', 'car_wash', 'casino', 'childcare', 'cinema', 'clinic', 'college',
                    'community_centre', 'courthouse', 'dentist', 'driving_school', 'embassy', 'fast_food',
                    'fire_station', 'fire_station', 'fuel', 'hospital', 'kindergarten', 'library', 'marketplace',
                    'nightclub', 'parking', 'place_of_worship', 'planetarium', 'police', 'police', 'prison', 'prison',
                    'pub', 'recycling', 'register_office', 'restaurant', 'school', 'social_facility', 'studio',
                    'theatre', 'toilets', 'townhall', 'tram_station', 'university')
                  then amenity
              when tourism = 'museum'
                  then tourism
              when leisure = 'sports_centre'
                  then leisure
              when landuse = 'residential'
                  and residential = 'rural'
                  then 'house'
              when landuse = 'residential'
                  and residential = 'urban'
                  then 'apartments'
              when landuse = 'residential'
                  then 'residential'
              when landuse in
                   ('garages', 'retail', 'commercial', 'industrial', 'construction', 'military', 'railway', 'service',
                    'allotments', 'railway', 'religious', 'brownfield')
                  then landuse
    end
from osm_landuse l
where use is null
  and ST_Intersects(l.geom, b.geom)
  and (landuse in
       ('residential', 'garages', 'retail', 'commercial', 'industrial', 'construction', 'military', 'railway',
        'service',
        'allotments', 'railway', 'religious', 'brownfield')
    or amenity in
       ('bank', 'bus_station', 'cafe', 'car_wash', 'casino', 'childcare', 'cinema', 'clinic', 'college',
        'community_centre', 'courthouse', 'dentist', 'driving_school', 'embassy', 'fast_food',
        'fire_station', 'fire_station', 'fuel', 'hospital', 'kindergarten', 'library', 'marketplace',
        'nightclub', 'parking', 'place_of_worship', 'planetarium', 'police', 'police', 'prison', 'prison',
        'pub', 'recycling', 'register_office', 'restaurant', 'school', 'social_facility', 'studio',
        'theatre', 'toilets', 'townhall', 'tram_station', 'university')
    or leisure = 'sports_centre'
    or tourism = 'museum'
    or residential in ('rural', 'urban'));

-- half of a table is updated
vacuum analyze osm_buildings;