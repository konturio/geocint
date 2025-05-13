drop table if exists osm_road_segments_h3;
create table osm_road_segments_h3  as (
    select
        11::int                                              as resolution,
        h3_lat_lng_to_cell(ST_StartPoint(s.geom)::point, 11) as h3,
        sum(ST_Length(s.geom::geography))                    as highway_length
    from osm_road_segments r,
         ST_DumpSegments(st_segmentize(r.seg_geom::geography, 25)::geometry) s
    where seg_geom is not null
    group by h3);

call generate_overviews('osm_road_segments_h3', '{highway_length}'::text[], '{sum}'::text[], 8);

create index on osm_road_segments_h3 (h3);