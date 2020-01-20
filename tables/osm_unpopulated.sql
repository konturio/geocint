drop table if exists osm_unpopulated;

create table osm_unpopulated as (
    select
        osm_type,
        osm_id,
        tags ->> 'natural' as natural,
        tags ->> 'landuse' as landuse,
        tags ->> 'population' as population,
        ST_Transform(geog::geometry, 3857) as geom
    from
        osm
    where
          (
                  (tags ->> 'natural') in ('wood', 'glacier', 'wetland', 'sand')
                  or (tags ->> 'landuse') in ('forest', 'quarry', 'farmland')
                  or tags @> '{"population":"0"}'
              )
      and ST_GeometryType(geog::geometry) != 'ST_Point'
      and ST_GeometryType(geog::geometry) != 'ST_LineString'
);

create index on osm_unpopulated using gist (geom);

