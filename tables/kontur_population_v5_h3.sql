drop table if exists kontur_population_v5_h3;
create table kontur_population_v5_h3 as (
    select h3::h3index                                                     as h3,
           8::integer                                                      as resolution,
           ST_Area(h3_cell_to_boundary_geography(h3::h3index)) / 1000000.0 as populated_area_km2,
           population
    from kontur_population_v5
);

call generate_overviews('kontur_population_v5_h3', '{population, populated_area_km2}'::text[], '{sum, sum}'::text[], 8);