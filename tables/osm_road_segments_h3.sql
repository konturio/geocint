drop table if exists osm_road_segments_h3;
create table osm_road_segments_h3  as (
    select
        8::int as resolution,
        h3_lat_lng_to_cell(ST_StartPoint(seg_geom)::point, 8) as h3,
        sum(length) as highway_length
    from osm_road_segments
    where seg_geom is not null
    group by h3);
