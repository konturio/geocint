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

-- use number of dimensions to define which type of regression should be applied
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
with area_regr as (select regr_slope(capacity, area)         as slope,
                          regr_intercept(capacity, area)     as intercept
                   from osm_car_parkings_capacity_mid1
                   where area is not null
                         and capacity is not null),
     length_regr as (select regr_slope(capacity, length)     as slope,
                            regr_intercept(capacity, length) as intercept
                     from osm_car_parkings_capacity_mid1
                     where length is not null
                           and capacity is not null)
select osm_id                                                as osm_id,
       osm_type                                              as osm_type,
       ndimension,
       case
           when capacity is null and ndimension = 2
                then coalesce(area * ar.slope + ar.intercept, 0)
           when capacity is null and ndimension = 1
                then coalesce(length * lr.slope + lr.intercept, 0)
           else capacity
       end                                                   as capacity,
       ST_Buffer(
                 case 
                     -- we need it to prevent broken burref of closed linear parkings
                     when ndimension = 1 then ST_ConvexHull(ST_Normalize(geog::geometry))::geography
                     else geog
                 end, 700 )                                  as buffered_geom,
       ST_Normalize(geog::geometry)                          as geom
into osm_car_parkings_capacity
from area_regr   as ar,
     length_regr as lr,
     osm_car_parkings_capacity_mid1;

create index on osm_car_parkings_capacity using gist(geom);

-- drop temporary tables
drop table if exists osm_car_parkings_capacity_in;
drop table if exists osm_car_parkings_capacity_mid1;
