drop table if exists land_polygons_h3_r8_in;

create table land_polygons_h3_r8_in as (
    select distinct
        h3_polyfill(geom, 8) h3
    from
        land_polygons_vector
);

drop table if exists land_polygons_h3_r8;
create table land_polygons_h3_r8 as (
    select l.h3     as h3,
           hex.geom as geom,
           hex.area as area
    from land_polygons_h3_r8_in l,
         ST_HexagonFromH3(l.h3) hex
    group by 1, 2, 3
);

-- Remove temporary table
drop table if exists land_polygons_h3_r8_in;