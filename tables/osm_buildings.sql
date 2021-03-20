drop table if exists osm_buildings;
create table osm_buildings as (
    select osm_type,
           osm_id,
           tags ->> 'building'         as building,
           tags ->> 'addr:street'      as street,
           tags ->> 'addr:housenumber' as hno,
           tags ->> 'building:levels'  as levels,
           tags ->> 'height'           as height,
           coalesce(tags ->> 'building:use',
                    case
                        when tags ->> 'building' in
                             ('apartments', 'cathedral', 'chapel', 'church', 'civic', 'clinic',
                              'college', 'commercial',
                              'construction', 'dormitory', 'fire_station', 'garages',
                              'government', 'greenhouse', 'hospital',
                              'hotel', 'house', 'kindergarten', 'kiosk', 'office', 'parking',
                              'prison', 'public', 'residential',
                              'retail', 'school', 'service', 'sports_centre', 'sports_hall',
                              'stadium', 'train_station',
                              'transportation', 'university')
                            then tags ->> 'building'
                        when tags ->> 'building' in ('factory', 'warehouse', 'hangar', 'industrial')
                            then 'industrial'
                        end)           as use,
           tags ->> 'name'             as "name",
           tags,
           geog::geometry              as geom
    from osm o
    where tags ? 'building'
      and not (tags ->> 'building') = 'no'
    order by _ST_SortableHash(geog::geometry)
);

create index on osm_buildings using brin(geom) where use is null;

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
  and ST_DWithin(l.geom, b.geom, 0);
