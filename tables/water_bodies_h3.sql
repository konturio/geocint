-- derive h3 cells for inland water bodies
-- we exclude oceans and seas
-- create hexagons at resolution 8 covering inland water geometry

drop table if exists water_bodies_in;
create table water_bodies_in as (
	select ST_Buffer(ST_Transform(geom,4326)::geography, 500) as geom,
	       geom                                               as geom3857
    from osm_water_polygons_in_subdivided
    union all
    select ST_Subdivide(ST_Buffer(ST_Transform(geom,4326)::geography, 500)::geometry,100) as geom,
	       geom                                                                           as geom3857
    from osm_water_lines
);

create index on water_bodies_in using gist(geom3857);

drop table if exists water_bodies_h3_in;
create table water_bodies_h3_in as (
    select h3_polygon_to_cells(geom, 8)                                                   as h3,
           ST_Transform(h3_cell_to_boundary_geometry(h3_polygon_to_cells(geom, 8)), 3857) as geom
    from water_bodies_in w
);

create index on water_bodies_h3_in using gist(geom);

-- final table with geometry for convenience

drop table if exists water_bodies_h3;
create table water_bodies_h3 as (
    select i.h3                                                   as h3,
           ST_Transform(h3_cell_to_boundary_geometry(i.h3), 3857) as geom
    from water_bodies_h3_in i, 
         water_bodies_in p
    where ST_Intersects(i.geom, p.geom3857)
    group by 1
);

-- cleanup temporary table

drop table if exists water_bodies_in;
drop table if exists water_bodies_h3_in;

create index on water_bodies_h3 (h3);
create index on water_bodies_h3 using gist(geom);
