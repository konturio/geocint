drop table if exists osm_buildings_japan;
create table osm_buildings_japan as (
    select building,
           street,
           hno,
           levels,
           height,
           use,
           "name",
           geom
    from osm_buildings b
    where ST_Dimension(geom) != 1
      and ST_DWithin(
            b.geom, (
                select geog::geometry
                from osm
                where tags @> '{"name:en":"Japan", "boundary":"administrative"}'
                  and osm_id = 382313
                  and osm_type = 'relation'),
            0)
);
