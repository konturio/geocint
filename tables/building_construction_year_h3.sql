-- average building construction year per h3
drop table if exists building_year_points_in;
create table building_year_points_in as (
    select parse_start_year(tags ->> 'start_date') as start_year,
           ST_PointOnSurface(geog::geometry)                                     as geom           
    from osm
    where tags ? 'building'
      and tags ? 'start_date'
);

drop table if exists building_year_points;
create table building_year_points as (
    select start_year,
           geom           
    from building_year_points_in
    where start_year is not null
          and start_year <= extract(year from current_date)
);

drop table if exists building_construction_year_h3;
create table building_construction_year_h3 as (
    select h3_lat_lng_to_cell(geom::point, 8) as h3,
           min(start_year)::float             as min_osm_building_construction_year,
           max(start_year)::float             as max_osm_building_construction_year,
           avg(start_year)::float             as avg_osm_building_construction_year,
           8                                  as resolution
    from building_year_points
    group by 1
);

drop table if exists building_year_points_in;
drop table if exists building_year_points;

call generate_overviews('building_construction_year_h3', '{min_osm_building_construction_year,max_osm_building_construction_year,avg_osm_building_construction_year}'::text[], '{min,max,avg}'::text[], 8);
