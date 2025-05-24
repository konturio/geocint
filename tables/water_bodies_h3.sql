-- derive h3 cells for inland water bodies
-- we exclude oceans and seas
-- create hexagons at resolution 8 covering inland water geometry

drop table if exists water_bodies_h3_in;
create table water_bodies_h3_in as (
    select distinct
        h3_polygon_to_cells(geom, 8) as h3
    from (
        select geom from osm_water_polygons_in_subdivided
        union all
        select geom from osm_water_lines_buffers_subdivided
    ) w
);

-- final table with geometry for convenience

drop table if exists water_bodies_h3;
create table water_bodies_h3 as (
    select h3,
           st_transform(h3_cell_to_boundary_geometry(h3), 3857) as geom
    from water_bodies_h3_in
    group by 1,2
);

create index on water_bodies_h3 (h3);
create index on water_bodies_h3 using gist(geom);

-- cleanup temporary table

drop table if exists water_bodies_h3_in;
