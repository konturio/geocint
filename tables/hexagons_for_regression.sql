-- Table with geometry where there were no Facebook roads originally
drop table if exists hexagons_for_regression_in;
create table hexagons_for_regression_in as (
	-- Iran, North Korea, Syria, Alaska, Greenland
	select ST_Subdivide(geom, 50) as geom
	from kontur_boundaries
	where hasc_wiki in ('IR', 'KP', 'SY', 'US.AK', 'GL', 'SJ')
	union all
	-- North part of Russia
	select  ST_Subdivide(
		       	ST_Intersection(geom, 
		       	       	       'SRID=4326;POLYGON((47.98 90,47.98 66.18,51.41 66.18,51.41 61.25,168.0 61.25,168.00 90,47.98 90))'::geometry),
		       	50) as geom
	from kontur_boundaries
	where hasc_wiki = 'RU'
	union all
	-- North part of Canada
	select  ST_Subdivide(
		        ST_Difference(k.geom,
		        	         'SRID=4326;POLYGON((-137 56,-130.26 55.4,-129.2 55.4,-129.2 54.977,-101.778 54.977,-101.778 52.16,
		        	         -63.45 52.16,-63.45 60.43,-57.5 64.6,-45 37,-127 37,-137 56))'::geometry), 50)
    from kontur_boundaries k
    where hasc_wiki = 'CA'
);

drop table if exists hexagons_for_regression_mid;
create table hexagons_for_regression_mid as (
	select ST_Transform(geom, 3857) as geom
	from hexagons_for_regression_in
);

create index on hexagons_for_regression_mid using gist(geom);

drop table if exists hexagons_for_regression;
create table hexagons_for_regression as (
	select l.h3
	from land_polygons_h3_r8 l,
	     hexagons_for_regression_mid h
	where ST_Intersects(l.geom, h.geom)
);
