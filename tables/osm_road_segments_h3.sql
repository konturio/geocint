drop table if exists osm_road_segments_h3;
create table osm_road_segments_h3 as (
    select
        8::int as resolution,
        h3_geo_to_h3(ST_StartPoint(seg_geom), 8) as h3,
        sum(length) as highway_length
    from osm_road_segments
    group by h3);
