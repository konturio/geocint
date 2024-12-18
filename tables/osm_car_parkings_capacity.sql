-- The parking lot of the West Edmonton Mall in Edmonton, Alberta, Canada,
-- holds the world record for the largest parking lot in the world.
-- The lot, which can accomodate an estimated 20,000 vehicles was opened in 1981.

drop table if exists osm_car_parkings_capacity_in;
create table osm_car_parkings_capacity_in as (
    select distinct on (osm_type, osm_id)
            osm_type,
            osm_id,
            ST_Dimension(ST_Normalize(geog::geometry)) as ndimension,
            case
                when tags ->> 'leisure' = 'stadium' then null -- so as not to confuse stadium capacity with the parking capacity
                when parse_integer(tags ->> 'capacity') < 0 then abs(parse_integer(tags ->> 'capacity'))
                when parse_integer(tags ->> 'capacity') > 25000 then null
                else parse_integer(tags ->> 'capacity')
            end                                        as capacity,
            geog                                       as geog
    from osm o
    where (tags ->> 'amenity' in ('parking', 'parking_space')
          or (tags ? 'parking' and tags ->> 'parking' not in ('no','disabled')))
    order by 1, 2, ST_Dimension(ST_Normalize(geog::geometry)) desc
);

drop table if exists osm_car_parkings_capacity_mid1;
create table osm_car_parkings_capacity_mid1 as (
    select osm_id,
           osm_type,
           ndimension,
           case
               when ndimension = 2 then ST_Area(geog)
               else null
           end as area,
           case
               when ndimension = 1 then ST_Length(geog)
               else null
           end as length,
           case
               when capacity is null and ndimension = 0 then 1
               else capacity
           end as capacity,
           geog
    from osm_car_parkings_capacity_in
);

-- calculate regression coefficients for area and length
drop table if exists osm_car_parkings_capacity;
with ar as (select regr_slope(capacity, area)       as slope,
                   regr_intercept(capacity, area)   as intercept
            from osm_car_parkings_capacity_mid1
            where area is not null
                  and capacity is not null),
     lr as (select regr_slope(capacity, length)     as slope,
                   regr_intercept(capacity, length) as intercept
            from osm_car_parkings_capacity_mid1
            where length is not null
                  and capacity is not null)
-- calculate where it doesn't exists
select osm_id       as osm_id,
       osm_type     as osm_type,
       ndimension,
       case
           when capacity is null and ndimension = 2
                then coalesce(area * ar.slope + ar.intercept, 0)
           when capacity is null and ndimension = 1
                then coalesce(length * lr.slope + lr.intercept, 0)
           else capacity
       end          as capacity,
       ST_Buffer(
                 case 
                     when ndimension = 1 then ST_ConvexHull(ST_Normalize(geog::geometry))::geography
                     else geog
                 end, 700 ) as buffered_geom,
       ST_Normalize(geog::geometry) as geom
into osm_car_parkings_capacity
from ar,
     lr,
     osm_car_parkings_capacity_mid1;

-- drop table if exists osm_car_parkings_capacity_in;
-- drop table if exists osm_car_parkings_capacity_mid1;


drop table if exists osm_car_parkings_capacity_h3_in;
create table osm_car_parkings_capacity_h3_in as (
    select h3,
           h3_cell_to_boundary_geometry(h3) as geom
    from (select h3_polygon_to_cells(buffered_geom, 8) as h3
        from osm_car_parkings_capacity
        where ndimension > 0 and capacity > 1) as sq
);

create index on osm_car_parkings_capacity_h3_in using gist(geom);

create index on osm_car_parkings_capacity using gist(geom);


select count(*) from (select osm_id, osm_type from  osm_car_parkings_capacity_h3_in a,
                osm_car_parkings_capacity b
          where ST_Intersects(a.geom, b.geom)
                and b.ndimension > 0
                and capacity > 1 group by osm_id, osm_type) a;

select count(*) from (select osm_id, osm_type from  osm_car_parkings_capacity b
          where  b.ndimension > 0
                and capacity > 1 group by osm_id, osm_type) a;













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




drop table if exists osm_car_parkings_capacity_h32;
create table osm_car_parkings_capacity_h32 as (
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