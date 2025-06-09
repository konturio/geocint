-- count wind farms from OSM
-- layer with count of generators that are wind turbines

drop table if exists wind_farms_h3_in;
create table wind_farms_h3_in as (
    select ST_PointOnSurface(geog::geometry) as geom
    from osm
    where tags @> '{"power":"generator"}'
      and tags @> '{"generator:method":"wind_turbine"}'
);

drop table if exists wind_farms_h3;
create table wind_farms_h3 as (
    select h3_lat_lng_to_cell(geom::point, 8) as h3,
           count(*) as wind_farms,
           8 as resolution
    from (
        select distinct on (h3_lat_lng_to_cell(geom::point, 11)) geom
        from wind_farms_h3_in
    ) s
    group by 1
);

drop table if exists wind_farms_h3_in;

call generate_overviews('wind_farms_h3', '{wind_farms}'::text[], '{sum}'::text[], 8);

create index on wind_farms_h3 (h3);
