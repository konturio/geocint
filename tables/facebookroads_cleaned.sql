create index if not exists osm_roads_geog_idx on osm_roads using gist((geom::geography));
drop table if exists facebookroads_cleaned;
create table facebookroads_cleaned as
select f.*
from facebook_roads f
left join lateral (
        select st_buffer(ST_collect(o.geom)::geography, 10) geog --selects geometries into a collection based on buffer size 10
        from osm_roads o
        where ST_DWithin (f.geom::geography, o.geom::geography, 10)
) o2 on true
where o2.geog is null  -- select all facebook roads that are not within 10 meters with osm roads
        -- select facebook roads with less than 50% intersection length with 10m buffer from osm roads
        or st_length(ST_intersection(f.geom::geography, o2.geog)) < 0.5 * st_length(f.geom::geography) 