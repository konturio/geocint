drop table if exists kontur_population_v5_h3;
create table kontur_population_v5_h3 as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3,
           8::integer                               as resolution,
           population
    from kontur_population_v5
);