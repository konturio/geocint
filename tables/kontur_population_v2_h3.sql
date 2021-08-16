drop table if exists kontur_population_v2_h3;
create table kontur_population_v2_h3 as (
    select h3_geo_to_h3(ST_PointOnSurface(geom), 8) as h3,
           8::integer                               as resolution,
           population
    from kontur_population_v2
);
