-- The parking lot of the West Edmonton Mall in Edmonton, Alberta, Canada,
-- holds the world record for the largest parking lot in the world.
-- The lot, which can accomodate an estimated 20,000 vehicles was opened in 1981.

drop table if exists osm_car_parkings_capacity_in;
create table osm_car_parkings_capacity_in as (
    select  distinct on (osm_id, osm_type) osm_type,
            osm_id,
            ST_Area(geog) as area,
            ST_GeometryType(geog::geometry)    as gtype,
            case
                when tags ->> 'leisure' = 'stadium' then null -- so as not to confuse stadium capacity with the parking capacity
                when parse_integer(tags ->> 'capacity') < 0 then abs(parse_integer(tags ->> 'capacity'))
                when parse_integer(tags ->> 'capacity') > 25000 then null
                else parse_integer(tags ->> 'capacity')
            end as capacity,
            tags,
            geog as geog
    from osm o
    where (tags ->> 'amenity' in ('parking', 'parking_space')
          or (tags ? 'parking' and tags ->> 'parking' not in ('no','disabled')))
    order by 1,2,_ST_SortableHash(geog::geometry)
);

drop table if exists osm_car_parkings_capacity_mid1;
create table osm_car_parkings_capacity_mid1 as (
    select osm_id,
           osm_type,
           area,
           capacity,
           ST_Normalize(geog::geometry)         as geom
    from osm_car_parkings_capacity_in
    where gtype in ('ST_MultiPolygon', 'ST_Polygon')
    union all
    select osm_id,
           osm_type,
           ST_Area(ST_MakePolygon(geog::geometry)::geography) as area,
           capacity,
           ST_Normalize(geog::geometry)         as geom
    from osm_car_parkings_capacity_in
    where gtype = 'ST_LineString'
          and ST_IsClosed(geog::geometry)
    union all
    select osm_id,
           osm_type,
           null as area,
           case
               when capacity = 0 or capacity is null then 1
               else capacity
           end as capacity,
           ST_Normalize(geog::geometry)         as geom
    from osm_car_parkings_capacity_in
    where (gtype = 'ST_LineString' and not ST_IsClosed(geog::geometry))
          or gtype = 'ST_Point'
);

drop table if exists osm_car_parkings_capacity_in;

-- calculate regression coefficients
drop table if exists osm_car_parkings_capacity;
with regression as (select regr_slope(capacity, area)     as slope,
                           regr_intercept(capacity, area) as intercept
                    from osm_car_parkings_capacity_mid1
                    where area is not null
                          and capacity is not null)
-- calculate where it doesn't exists
select osm_id                        as osm_id,
       osm_type                      as osm_type,
       case
           when capacity is null or (capacity = 0 and area is not null)
                then coalesce(area * regression.slope + regression.intercept, 0.0101)
           else capacity
       end                           as capacity,
       area,
       geom
into osm_car_parkings_capacity
from regression,
     osm_car_parkings_capacity_mid1;

drop table if exists osm_car_parkings_capacity_mid1;
