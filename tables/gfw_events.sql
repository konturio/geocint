set timezone to 'UTC';

drop table if exists gfw_events;
create table gfw_events as (
    select json->>'id' as event_id,
           json->>'type' as type,
           (json->>'start')::timestamptz as ts_start,
           (json->>'end')::timestamptz as ts_end,
           st_setsrid(st_makepoint((json#>>'{position,lon}')::float,
                                   (json#>>'{position,lat}')::float),4326) as geom,
           json#>>'{vessel,id}' as vessel_id,
           json#>>'{portVisit,portId}' as port_id,
           json#>>'{portVisit,portName}' as port_name,
           (json#>>'{confidence,level}')::int as confidence_level
    from gfw_events_raw
);

create index on gfw_events using gist(geom);
