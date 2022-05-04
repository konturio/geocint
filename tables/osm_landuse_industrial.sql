drop table if exists osm_landuse_industrial;
create table osm_landuse_industrial as (
    select osm_id,
           osm_type,
           tags ->> 'landuse'                                   as landuse,
           coalesce(tags ->> 'industrial', tags ->> 'man_made') as industrial,
           geog::geometry                                       as geom
    from osm
    where (
            tags ? 'industrial'
            or tags @> '{"man_made":"works"}'
            or tags @> '{"landuse":"harbour"}'
            or tags @> '{"landuse":"industrial"}')
      and ST_Dimension(geog::geometry) = 2
);

create index on osm_landuse_industrial using gist (geom);