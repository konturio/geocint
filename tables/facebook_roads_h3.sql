drop table if exists facebook_roads_h3;
create table facebook_roads_h3 as
		(select 8::int as resolution,
				h3_geo_to_h3(ST_PointOnSurface(geom::geometry)::point, 8)as h3,
				sum(ST_Length(geom::geography)) as fb_roads_length
		from 
			(select * from facebook_roads limit 100000) as a 
		group by h3);
