drop table if exists osm_ports;
create table osm_ports as (
    select distinct on (osm_id, osm_type)
           osm_type,
           osm_id,
           geog::geometry as geom,
           tags ->> 'name' as name,
           tags
    from osm o
    where tags @> '{"landuse":"port"}'
       or (tags @> '{"landuse":"industrial"}' and tags @> '{"industrial":"port"}')
       or tags @> '{"harbour":"port"}'
       or tags @> '{"harbour":"yes"}'
    order by 1,2,_ST_SortableHash(geog::geometry)
);
create index on osm_ports using gist (geom);
