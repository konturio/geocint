drop table if exists fb_osm_countries;
create table fb_osm_countries as (select ST_Subdivide(ST_Transform(geog::geometry,3857)) as geom, tags->>'name' as name, tags->>'ISO3166-1:alpha3' as iso from osm where tags @> '{"admin_level":"2", "boundary":"administrative"}' 
	and osm_type='relation'); 

drop table if exists fb_africa_population_boundary;
create table fb_africa_population_boundary as (select * from osm_countries c where exists(select from fb_africa_population_vector p where ST_Intersects(p.geom, c.geom)));

delete from fb_africa_population_boundary where iso in ('ETH', 'SSD', 'SDN', 'SOM','MAR') or iso is null;

drop table fb_osm_countries;
