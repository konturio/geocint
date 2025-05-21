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
                     and (not (tags ? 'building') or tags ->> 'building' != 'train_station')
                     and (not (tags ? 'subway') or tags ->> 'subway' != 'yes')
                    then 'railway_station'
                when ((tags ->> 'highway' = 'bus_stop'
                     or tags ->> 'public_transport' in ('stop_position', 'station')
                     or tags ->> 'railway' = 'tram_stop')
                     and (not (tags ? 'train') or tags ->> 'train' != 'yes'))
                     or (tags ->> 'railway' = 'station'
                     and (tags ->> 'building' = 'train_station' or tags ->> 'subway' = 'yes'))
                    then 'public_transport_stops'
                end as type,
            tags ->> 'name' as name,
            tags
    from osm o
    -- index-friendly tag compares
    where (tags @> '{"aeroway":"aerodrome"}'
          and (tags ->> 'landuse' not in ('military', 'construction') or tags ->> 'landuse' is null))
          or tags @> '{"railway":"station"}'
          or ((tags @> '{"highway":"bus_stop"}' or tags @> '{"public_transport":"stop_position"}' or tags @> '{"railway":"tram_stop"}')
          and (not (tags ? 'train') or tags ->> 'train' != 'yes'))
    order by 1,2,_ST_SortableHash(geog::geometry)
);