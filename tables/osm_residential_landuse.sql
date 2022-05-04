drop table if exists osm_residential_landuse;
create table osm_residential_landuse as (
    select
        osm_type,
        osm_id,
        tags ->> 'landuse' as landuse,
        -- ST_Transform(ST_ClipByBox2D(geog::geometry, ST_Transform(ST_TileEnvelope(0,0,0),4326)), 3857) as geom
        ST_Transform(geog::geometry, 3857) as geom
    from
        osm
    where
        tags @> '{"landuse":"residential"}'
);

create index on osm_residential_landuse using gist (geom);
