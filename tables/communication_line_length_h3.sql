-- length of communication lines from OSM

drop table if exists communication_lines;
create table communication_lines as (
    select geog::geometry as geom
    from osm
    where tags @> '{"communication":"line"}'
      and ST_GeometryType(geog::geometry) = 'ST_LineString'
);

call linear_segments_length_to_h3('communication_lines', 'communication_line_length_h3', 'split_and_dump', 'communication_length', 11, 25);

call generate_overviews('communication_line_length_h3', '{communication_length}'::text[], '{sum}'::text[], 11);

create index on communication_line_length_h3(h3);

drop table if exists communication_lines;
