drop table if exists land_polygons_h3_r8;

create table land_polygons_h3_r8 as (
    select distinct
        h3_polyfill(geom, 8) h3
    from
        land_polygons_vector
);
