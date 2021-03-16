drop table if exists osm_buildings_in;
create table osm_buildings_in as (
    select osm_type,
           osm_id,
           tags ->> 'building'         as building,
           tags ->> 'addr:street'      as street,
           tags ->> 'addr:housenumber' as hno,
           tags ->> 'building:levels'  as levels,
           tags ->> 'height'           as height,
           tags ->> 'building:use'     as use,
           tags ->> 'name'             as "name",
           tags,
           geog::geometry              as geom
    from osm o
    where tags ? 'building'
      and not (tags ->> 'building') = 'no'
    order by _ST_SortableHash(geog::geometry)
);

create index on osm_buildings_in using brin (geom);

drop table if exists osm_buildings;
create table osm_buildings as (
    select b.osm_type,
           b.osm_id,
           building,
           street,
           hno,
           levels,
           height,
           case
               when building in
                    ('apartments', 'cathedral', 'chapel', 'church', 'civic', 'clinic', 'college', 'commercial',
                     'construction', 'dormitory', 'fire_station', 'garages', 'government', 'greenhouse', 'hospital',
                     'hotel', 'house', 'kindergarten', 'kiosk', 'office', 'parking', 'prison', 'public', 'residential',
                     'retail', 'school', 'service', 'sports_centre', 'sports_hall', 'stadium', 'train_station',
                     'transportation', 'university')
                   and use is null
                   then building
               when building in ('factory', 'warehouse', 'hangar', 'industrial')
                   and use is null
                   then 'industrial'
               when landuse in
                    ('garages', 'retail', 'commercial', 'industrial', 'construction', 'military', 'railway', 'service',
                     'allotments', 'railway', 'religious', 'brownfield')
                   and use is null
                   then landuse
               when amenity in
                    ('bank', 'bus_station', 'cafe', 'car_wash', 'casino', 'childcare', 'cinema', 'clinic', 'college',
                     'community_centre', 'courthouse', 'dentist', 'driving_school', 'embassy', 'fast_food',
                     'fire_station', 'fire_station', 'fuel', 'hospital', 'kindergarten', 'library', 'marketplace',
                     'nightclub', 'parking', 'place_of_worship', 'planetarium', 'police', 'police', 'prison', 'prison',
                     'pub', 'recycling', 'register_office', 'restaurant', 'school', 'social_facility', 'studio',
                     'theatre', 'toilets', 'townhall', 'tram_station', 'university')
                   and use is null
                   then amenity
               when tourism = 'museum'
                   and use is null
                   then tourism
               when leisure = 'sports_centre'
                   and use is null
                   then leisure
               when landuse = 'residential'
                   and residential = 'rural'
                   and use is null
                   then 'house'
               when landuse = 'residential'
                   and residential = 'urban'
                   and use is null
                   then 'apartments'
               when landuse = 'residential'
                   and use is null
                   then 'residential'
               end
                     use,
           "name",
           b.tags as tags,
           b.geom as geom
    from osm_buildings_in b,
         osm_landuses l
    where ST_Intersects(b.geom, l.geom)
);

drop table if exists osm_buildings_in;
