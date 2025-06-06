drop table if exists motor_vehicle_road_length_h3;
create table motor_vehicle_road_length_h3 as (
    select h3_lat_lng_to_cell(ST_StartPoint(s.geom)::point, 11) as h3,
           11::int                                              as resolution,
           sum(ST_Length(s.geom::geography))                    as motor_vehicle_road_length
    from osm_road_segments r,
         ST_DumpSegments(ST_Segmentize(r.seg_geom::geography, 25)::geometry) s
    where seg_geom is not null 
          and drive_time is not null
    group by h3);

call generate_overviews('motor_vehicle_road_length_h3', '{motor_vehicle_road_length}'::text[], '{sum}'::text[], 11);

create index on motor_vehicle_road_length_h3 (h3);
