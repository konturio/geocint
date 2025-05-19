-- average building construction year per h3

drop table if exists building_year_points;
create table building_year_points as (
    select ST_PointOnSurface(geog::geometry) as geom,
           parse_integer(regexp_replace(tags->>'start_date', '[^0-9]', '', 'g')) as year
    from osm
    where tags ? 'building'
      and tags ? 'start_date'
);

-- keep only valid years
delete from building_year_points where year is null or year < 1000 or year > extract(year from current_date);

create table building_start_year_h3 as (
    select h3_lat_lng_to_cell(geom::point, 8) as h3,
           avg(year)::float as start_year,
           8 as resolution
    from building_year_points
    group by 1
);

create index on building_start_year_h3(h3);

drop table if exists building_year_points;
