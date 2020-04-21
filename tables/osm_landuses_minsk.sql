drop table if exists osm_landuses_minsk;

create table osm_landuses_minsk as (
    select *
    from osm_landuses
    where ST_DWithin(
                  osm_landuses.geom,
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