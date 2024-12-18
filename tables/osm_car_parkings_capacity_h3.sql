drop table if exists osm_car_parkings_capacity_h3;
create table osm_car_parkings_capacity_h3 as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3,
           sum(capacity)                                         as osm_car_parkings_capacity,
           8::integer                                            as resolution
    from osm_car_parkings_capacity
    group by 1
);

call generate_overviews('osm_car_parkings_capacity_h3', '{osm_car_parkings_capacity}'::text[], '{sum}'::text[], 8);








drop table if exists osm_car_parkings_capacity_h3_in;
create table osm_car_parkings_capacity_h3_in as (
    select a.h3,
           ST_Transform(h3_cell_to_boundary_geometry(a.h3), 3857) as geom
    from (select h3_polygon_to_cells(ST_Transform(ST_Buffer(geom, 600), 4326),8) as h3
          from osm_car_parkings_capacity
          where ndimension > 0
                and capacity > 1
          group by 1) a
);

create index on osm_car_parkings_capacity_h3_in using gist(geom);

drop table if exists osm_car_parkings_capacity_h3;
create table osm_car_parkings_capacity_h3 as (
    select h3,
           sum(osm_car_parkings_capacity) as osm_car_parkings_capacity,
           resolution
    from ((select a.h3,
                 sum(case
                         when ndimension = 2
                             then round(capacity::float*ST_Area(ST_Intersection(a.geom, b.geom))/ST_Area(b.geom))
                             else round(capacity::float*ST_Length(ST_Intersection(a.geom, b.geom))/ST_Length(b.geom))
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
