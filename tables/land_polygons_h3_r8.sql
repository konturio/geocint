drop table if exists land_polygons_h3_r8_in;

create table land_polygons_h3_r8_in as (
    select distinct
        h3_polygon_to_cells(geom, 8) h3
    from
        land_polygons_vector
);

drop table if exists land_polygons_h3_r8;
create table land_polygons_h3_r8 as (
    select h3                                                   as h3,
           ST_Transform(h3_cell_to_boundary_geometry(h3), 3857) as geom,
           ST_Area(h3_cell_to_boundary_geography(h3))           as area
    from land_polygons_h3_r8_in
    group by 1, 2, 3
);

create index on land_polygons_h3_r8 (h3);

-- Remove temporary table
drop table if exists land_polygons_h3_r8_in;