create index on osm_roads using gist((geom::geography));


drop table if exists facebookroads_cleaned;

create table facebookroads_cleaned as
select fr.* -- select facebook roads that are within 10 meters of OSM roads. Then generate intersection lenght, if intersection lenght is less than 50% we drop it from selection
from facebook_roads fr
left join lateral (
	select st_buffer(ST_collect(osm.geom)::geography, 10)::geometry geom --selects geometries into a collection based on buffer size 10
	from osm_roads osm
	where ST_DWithin (fr.geom::geography, osm.geom::geography, 10)
) osm on true
where st_length(ST_intersection(fr.geom, osm.geom)::geography) < 0.5 * st_length(fr.geom::geography) --cacluate the length of intersection and make sure more than 50% is intersecting
union all
-- combines multiple select statements
select fr.*
from facebook_roads fr
left join osm_roads osm
	on ST_DWithin (fr.geom::geography, osm.geom::geography, 10) --join osm roads with fb roads within 10 meters
where osm.osm_id is null; -- select all facebook roads that are not within 10 meters with osm roads