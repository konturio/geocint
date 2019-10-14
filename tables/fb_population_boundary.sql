drop table if exists fb_population_boundary;
create table fb_population_boundary as (select gid, gid_0 as iso, name_0 as name, ST_Subdivide(geom) as geom from gadm_countries_boundary c where exists(select from fb_population_vector p, ST_Subdivide(c.geom) c_sub_geom where ST_Intersects(p.geom, c_sub_geom)));

