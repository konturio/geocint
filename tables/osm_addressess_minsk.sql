drop table if exists osm_addresses_minsk;

create table osm_addresses_minsk as (
    select *
    from osm_addresses
    where (tags ? 'addr:street' and tags ? 'addr:housenumber' or tags ? 'name')
          --     could the query below be correctly than above one?
          --     where (street is not null and hno is not null or tags ? 'name')
      and ST_DWithin(
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