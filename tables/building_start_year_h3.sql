-- average building construction year per h3
drop table if exists building_year_points_in;
create table building_year_points_in as (
    select parse_integer(regexp_replace(tags->>'start_date', '[^0-9]', '', 'g')) as start_year,
           ST_PointOnSurface(geog::geometry)                                     as geom           
    from osm
    where tags ? 'building'
      and tags ? 'start_date'
);

drop table if exists building_year_points;
create table building_year_points_in as (
    select start_year,
           geom           
    from building_year_points_in
    where start_year is not null 
          or start_year >= 1000 
          or start_year <= extract(start_year from current_date)
);

drop table if exists building_start_year_h3;
create table building_start_year_h3 as (
    select h3_lat_lng_to_cell(geom::point, 8) as h3,
           avg(start_year)::float             as start_year,
           8                                  as resolution
    from building_year_points
    group by 1
);

create index on building_start_year_h3(h3);

drop table if exists building_year_points_in;
drop table if exists building_year_points;
