-- Table with geometry where there were no Facebook roads originally
drop table if exists areas_for_regression;
create table areas_for_regression as (
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

create index on areas_for_regression using gist(geom);
