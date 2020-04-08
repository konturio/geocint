drop table if exists osm_addresses;

create table osm_addresses as (
    select osm_type,
           osm_id,
           tags ->> 'addr:street'      as street,
           tags ->> 'addr:housenumber' as hno,
           tags ->> 'name'             as name,
           geog::geometry              as geom
    from osm
    where tags ? 'addr:housenumber'
);