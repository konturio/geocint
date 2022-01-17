drop table if exists facebookroads_cleaned;
create table facebookroads_cleaned as
select fr.*
from facebook_roads fr --select facebookroads
left join lateral (
	select st_buffer(ST_collect(osm.geom)::geography, 10)::geometry geom --selects geometries into a collection based on buffer size 10
	from osm_roads osm
	where ST_DWithin (fr.geom::geography, osm.geom::geography, 10)
) osm on true
where st_length(st_intersection(fr.geom, osm.geom)::geography) < 0.5 * st_length(fr.geom::geography) --cacluate the length of intersection and make sure more than 50% is intersecting
union all 
select fr.*
from facebook_roads fr
left join osm_roads osm
on ST_DWithin (fr.geom::geography, osm.geom::geography, 10)
where osm.osm_id is null;