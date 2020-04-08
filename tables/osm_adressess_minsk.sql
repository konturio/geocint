drop table if exists osm_addresses_minsk;

create table osm_addresses_minsk as (
    select osm_type,
           osm_id,
           tags ->> 'addr:street'      as street,
           tags ->> 'addr:housenumber' as hno,
           tags ->> 'name'             as name,
           geog::geometry              as geom
    from osm
    where ST_DWithin(
                  osm.geog::geometry,
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