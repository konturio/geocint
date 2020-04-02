drop table if exists osm_building_minsk;

create table osm_building_minsk as (
    select osm_type,
           osm_id,
           tags ->> 'city' as city,
           tags ->> 'building' as building,
           tags ->> 'addr'     as address,
        -- ST_Transform(geog::geometry, (ST_Intersects(osm.geog, ), 4326), 3857) as geom
    from osm
    where
          tags @> '{"addr":"street"}' or
          tags @> '{"addr":"housenumber"}' or
          tags @> '{"building":"levels"}' or
          tags @> '{"building":"hospital"}' or
          tags @> '{"building":"plant"}' or
          tags @> '{"building":"school"}'
);

create index on osm_building_minsk using gist (geom);