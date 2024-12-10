drop table if exists osm_car_parkings_capacity_h3;
create table osm_car_parkings_capacity_h3 as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3,
           sum(capacity)                                         as osm_car_parkings_capacity,
           8::integer                                            as resolution
    from osm_car_parkings_capacity
    group by 1
);

call generate_overviews('osm_car_parkings_capacity_h3', '{osm_car_parkings_capacity}'::text[], '{sum}'::text[], 8);