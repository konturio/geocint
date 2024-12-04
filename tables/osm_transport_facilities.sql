drop table if exists osm_transport_facilities;
create table osm_transport_facilities as (
    select  distinct on (osm_id, osm_type) osm_type,
            osm_id,
            geog::geometry as geom,
            case
                when tags ->> 'aeroway' = 'aerodrome'
                     and (tags ->> 'landuse' not in ('military', 'construction') or tags ->> 'landuse' is null)
                    then 'airport'
                when tags ->> 'railway' = 'station'
                    then 'railway_station'
                when (tags ->> 'highway' = 'bus_stop'
                     or tags ->> 'public_transport' = 'stop_position'
                     or tags ->> 'railway' = 'tram_stop')
                     and (not (tags ? 'train') or tags ->> 'train' != 'yes')
                    then 'public_transport_stops'
                when tags ->> 'amenity' in ('parking', 'parking_space')
                     or tags ? 'parking'
                    then 'car_parking'
            end as type,
            tags ->> 'name' as name,
            tags
    from osm o
    where (tags ->> 'aeroway' = 'aerodrome'
              and (tags ->> 'landuse' not in ('military', 'construction') or tags ->> 'landuse' is null))
          or tags ->> 'railway' = 'station'
          or ((tags ->> 'highway' = 'bus_stop' or tags ->> 'public_transport' = 'stop_position' or tags ->> 'railway' = 'tram_stop')
              and (not (tags ? 'train') or tags ->> 'train' != 'yes'))
          or (tags ->> 'amenity' in ('parking', 'parking_space')
              or (tags ? 'parking' and tags ->> 'parking' not in ('no','disabled')))
    order by 1,2,_ST_SortableHash(geog::geometry)
);