drop table if exists osm_addresses_minsk;

create table osm_addresses_minsk as (
    select *
    from osm_addresses
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

create index on osm_addresses_minsk using gist (geom);