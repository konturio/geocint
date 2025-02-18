drop table if exists existing_solar_power_panels_in;
create table existing_solar_power_panels_in as (
    select ST_PointOnSurface(geog::geometry) as geom        
    from osm
    where tags @> '{"power":"plant","plant:source":"solar"}'
);

drop table if exists existing_solar_power_panels_h3;
create table existing_solar_power_panels_h3 as (
    select h3 as h3,
           count(h3) as solar_power_plants,
           8 as resolution
    -- use 11 level of h3 grid to merge duplicates
    from (select distinct on (h3_lat_lng_to_cell(geom::point, 11)) h3_lat_lng_to_cell(geom::point, 8) as h3
              from existing_solar_power_panels_in) a
    group by 1
);

drop table if exists existing_solar_power_panels_in;