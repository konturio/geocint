drop table if exists facebook_roads_h3;
create table facebook_roads_h3 as
		(select 8::int as resolution,
				h3_geo_to_h3(ST_PointOnSurface(geom)::point, 8)as h3,
				sum(ST_Length(geom::geography)) as fb_roads_length
		from facebookroads_cleaned as a 
		group by h3);
