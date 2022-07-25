drop table if exists mapswipe_hot_tasking_data_subdivide;
create table mapswipe_hot_tasking_data_subdivide as (
	select id, 
	       ST_Subdivide(geom, 50) geom 
	from mapswipe_hot_tasking_data
);

create index on mapswipe_hot_tasking_data_subdivide using gist(geom);

drop table if exists land_polygons_h3_r8_4326;
create table land_polygons_h3_r8_4326 as (
	select h3,
	       ST_Transform(geom, 4326) as geom,
	       area
	from land_polygons_h3_r8
);

drop table if exists mapswipe_hot_tasking_data_h3;
create table mapswipe_hot_tasking_data_h3 as (
	select l.h3, 
	       8 resolution, 
	       l.area as mapswipe_area 
	from mapswipe_hot_tasking_data_subdivide s, 
	     land_polygons_h3_r8_4326 l 
	where ST_Intersects(s.geom, l.geom) 
	group by 1, 3
);

-- Remove temporary table
drop table if exists mapswipe_hot_tasking_data_subdivide;
drop table if exists land_polygons_h3_r8_4326;	