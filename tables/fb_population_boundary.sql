drop table if exists fb_population_boundary;
create table fb_population_boundary as (select * from gadm_countries_boundary c where exists(select from fb_population_vector p where ST_Intersects(p.geom, c.geom)));

