drop table if exists osm_buildings_minsk;

create table osm_buildings_minsk as (
    select osm_type,
           osm_id,
           tags ->> 'building' as building,
           tags ->> 'addr:street' as street,
           tags ->> 'addr:housenumber' as hno,
           ST_Transform(geog::geometry, 3857) as geom
    from osm
    where tags ? 'building'
      and ST_DWithin(
            osm.geog,
            (
                select ST_Expand(geog::geometry, 0)::geography
                from osm
                where tags @> '{"name":"Минск", "boundary":"administrative"}'
                  and osm_id = 59195
                  and osm_type = 'relation'
                ),
            0
    )
);

create index on osm_buildings_minsk using gist (geom);
