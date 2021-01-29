drop table if exists osm_user_count_grid_h3;
create table osm_user_count_grid_h3 as (
    select resolution,
           h3,
           osm_user,
           count(*)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               as count,
           count(distinct hours)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  as hours,
           count(distinct hours)
           filter (where tags @>
                         ('{"amenity":"place_of_worship", "landuse":"farmyard", "source":"survey", "source":"gps", "waterway":"ditch", "waterway":"stream"}')
               or (tags ?
                   '{"addr:place", "addr:suburb", "alt_name", "amenity", "backrest", "barrier", "bench", "building:levels", "colour", "cutting", "door", "embankment", "emergency", "entrance", "fee", foot", "handrail", "hazard", "height", "healthcare", "hgv", "indoor", "internet_access", "junction", "leaf_type", "leisure", "lit", "loc_name", "man_made", "maxweight", "meadow," "name", "noexit", "old_name", "oneway", "opening_hours", "parking:lane", "playground", "phone", "power", "pump", "railway", "resource", "restriction", "seasonal", "segregated", "shelter", "shop", "smoking", "social_facility", "sport", "step_count", "substation", "surface", "tactile_paving", "tracktype", "traffic_calming", "traffic_sign", "traffic_signals", "wall", "wetland", "voltage"}')) as local_hours,
           count(distinct hours)
           filter (where tags @>
                         ('{"source":"Bing", "source":"digitalglobe", "source":"microsoft/BuildingFootprints", "source":"YahooJapan/ALPSMAP"}')
               or tags ?
                  '{"attribution", "border_type", "network", "power", "source", "source:addr", "source_ref", "population", "tiger:cfcc", "tiger:name_base"}')                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     as remote_hours,
           count(distinct hours)
           filter (where tags ?
                         '{"access", "description", "historic", "location", "material", "maxspeed", "start_date"}')                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               as unknown_hours
    from (
             select
                 resolution as resolution,
                 h3         as h3,
                 osm_user   as osm_user,
                 tags,
                 date_trunc('hour', ts) as hours
             from osm,
                  ST_H3Bucket(geog) as hex
             where ts > (select max(ts) - interval '2 years' from osm)
         ) z
    group by 1, 2, 3
);

create index on osm_user_count_grid_h3 (h3);

alter table osm_user_count_grid_h3 set (parallel_workers = 32);
