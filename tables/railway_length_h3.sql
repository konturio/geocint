-- length of railways from OSM

drop table if exists railway_lines;
create table railway_lines as (
    select geog::geometry as geom
    from osm
    where tags @> '{"railway":"rail"}'
      and ST_GeometryType(geog::geometry) = 'ST_LineString'
);

call linear_segments_length_to_h3('railway_lines', 'railway_length_h3', 'split_and_dump', 'railway_length', 11, 25);

create index on railway_length_h3(h3);

drop table if exists railway_lines;
