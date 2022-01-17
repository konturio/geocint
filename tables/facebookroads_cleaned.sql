DROP TABLE IF EXISTS facebookroads_cleaned;
create table facebookroads_cleaned as
select fr.*
FROM a_kosovo_fbroads fr --select facebookroads
LEFT join lateral (
	select st_buffer(st_collect(osm.geom)::geography, 10)::geometry geom
	from a_kosovo_osmroads osm
	where ST_DWithin (fr.geom::geography, osm.geom::geography, 10)
) osm on true
where st_length(st_intersection(fr.geom, osm.geom)::geography) < 0.5 * st_length(fr.geom::geography) --cacluate the length of intersection and make sure more than 50% is intersecting
union all 
select fr.*
FROM a_kosovo_fbroads fr
LEFT JOIN a_kosovo_osmroads osm
ON ST_DWithin (fr.geom::geography, osm.geom::geography, 10)
where osm.osm_id is null;