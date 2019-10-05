drop table if exists fb_africa_population_boundary;
create table fb_africa_population_boundary as (select gid, gid_0 as iso, name_0 as name, geom from gadm_countries_boundary c where exists(select from fb_africa_population_vector p where ST_Intersects(p.geom, c.geom)));

delete from fb_africa_population_boundary where iso in ('ETH', 'SSD', 'SDN', 'SOM','MAR') or iso is null;
