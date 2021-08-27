drop table if exists osm_water_lines_buffers_subdivided;

create table osm_water_lines_buffers_subdivided as (
    select osm_type,
           osm_id,
           ST_Subdivide(
                   ST_Buffer(
                           geom, 1
                       )
               ) as geom,
           tags
    from osm_water_lines
);