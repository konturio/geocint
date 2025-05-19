-- length of drivable roads aggregated to h3

call linear_segments_length_to_h3('osm_road_segments', 'motor_vehicle_road_length_h3', 'split_and_dump', 'road_length', 11, 25);

-- filter by drivable segments only
delete from motor_vehicle_road_length_h3 m
using osm_road_segments r
where h3_lat_lng_to_cell(ST_StartPoint(r.seg_geom)::point, 11) = m.h3
  and r.drive_time is null;

create index on motor_vehicle_road_length_h3(h3);
