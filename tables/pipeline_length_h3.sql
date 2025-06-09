-- length of pipelines from OSM

drop table if exists pipeline_lines;
create table pipeline_lines as (
    select geog::geometry as geom
    from osm
    where (tags @> '{"man_made":"pipeline"}' or tags ? 'pipeline')
      and ST_GeometryType(geog::geometry) = 'ST_LineString'
);

call linear_segments_length_to_h3('pipeline_lines', 'pipeline_length_h3', 'split_and_dump', 'pipeline_length', 11, 25);

call generate_overviews('pipeline_length_h3', '{pipeline_length}'::text[], '{sum}'::text[], 11);

create index on pipeline_length_h3(h3);

drop table if exists pipeline_lines;
