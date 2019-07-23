drop table if exists population_vector_nowater;
create table population_vector_nowater as (
	select * from population_vector p
	where not exists(select from osm_water_polygons w where ST_Intersects(w.geom, p.geom))
	order by p.geom);
vacuum population_vector_nowater;

