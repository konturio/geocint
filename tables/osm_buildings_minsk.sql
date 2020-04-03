drop table if exists osm_buildings_minsk;

create table osm_buildings_minsk as (
    select osm_type,
           osm_id,
           building,
           hno,
           levels,
           height,
           use,
           name,
           geom,
           ST_Transform(:geometry, 3857)
    from osm_buildings
    where ST_DWithin(
                  osm_buildings.geom,
                  ST_Transform(
                          (
                              select geog
                              from osm
                              where tags @> '{"name":"Минск", "boundary":"administrative"}'
                                and osm_id = 59195
                                and osm_type = 'relation'
                          )
                              ::geometry,
                          3857
                      ),
                  0
              )
);

create index on osm_buildings_minsk using gist (geom);
