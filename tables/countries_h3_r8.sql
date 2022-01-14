drop table if exists countries_h3_r8;
create table countries_h3_r8 as (
    select h3, h3_to_geo_boundary_geometry(h3) geom
    from kontur_boundaries c,
         ST_Subdivide(c.geom) sub,
         h3_polyfill(sub, 8) h3
    where admin_level = '2'
);
