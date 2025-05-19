drop table if exists osm_volcanos;
create table osm_volcanos as (
    select osm_id,
           tags ->> 'name'           as name,
           tags ->> 'volcano:status' as status,
           geog::geometry            as geom
    from osm
    -- index-friendly tag compares
    where tags @> '{"natural":"volcano"}'
      and tags ? 'volcano:status'
      and tags->>'volcano:status' in ('active', 'dormant')
      and ST_Dimension(geog::geometry) = 0
);

create index on osm_volcanos using gist (geom);