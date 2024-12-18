drop table if exists osm_car_parkings_capacity_h3_in;
create table osm_car_parkings_capacity_h3_in as (
    select h3,
           h3_cell_to_boundary_geometry(h3) as geom
    from (select h3_polygon_to_cells(buffered_geom, 8) as h3
        from osm_car_parkings_capacity
        where ndimension > 0 and capacity > 1
        group by 1) as sq
);

create index on osm_car_parkings_capacity_h3_in using gist(geom);

-- distribute capacity across hexagons proportionally to the area/length of the intersecting segment
drop table if exists osm_car_parkings_capacity_h3;
create table osm_car_parkings_capacity_h3 as (
    select h3,
           sum(osm_car_parkings_capacity) as osm_car_parkings_capacity,
           resolution
    from ((select a.h3,
                 sum(case
                         when ndimension = 2
                             then capacity::float*ST_Area(ST_Intersection(a.geom, b.geom))/ST_Area(b.geom)
                             else capacity::float*ST_Length(ST_Intersection(a.geom, b.geom))/ST_Length(b.geom)
                     end)                                               as osm_car_parkings_capacity,
                 8::integer                                             as resolution
          from  osm_car_parkings_capacity_h3_in a,
                osm_car_parkings_capacity b
          where ST_Intersects(a.geom, b.geom)
                and b.ndimension > 0
                and capacity > 1
          group by 1)
          union all
          (select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3,
                 sum(capacity)                                          as osm_car_parkings_capacity,
                 8::integer                                             as resolution
          from osm_car_parkings_capacity
          where ndimension = 0
                or capacity <= 1
          group by 1)) sq
    group by 1,3
);

call generate_overviews('osm_car_parkings_capacity_h3', '{osm_car_parkings_capacity}'::text[], '{sum}'::text[], 8);
