drop table if exists osm_addresses_kosovo;

create table osm_addresses_kosovo as (
    select osm_type,
           osm_id,
           tags ->> 'place:municipality' as municipality,
           tags ->> 'addr:city'          as city,
           tags ->> 'addr:town'          as town,
           tags ->> 'addr:village'       as village,
           tags ->> 'addr:suburb'        as suburb,
           tags ->> 'addr:street'        as street,
           tags ->> 'addr:housenumber'   as hno,
           tags ->> 'name'               as "name",
           tags,
           geog::geometry                as geom
    from osm
    where tags ? 'addr:housenumber'
      and ST_DWithin(
            geog::geometry,
            (
                select geog::geometry
                from osm
                where tags @> '{"name:en":"Kosovo", "boundary":"administrative"}'
                  and osm_id = 2088990
                  and osm_type = 'relation'
            ),
            0
        )
);
