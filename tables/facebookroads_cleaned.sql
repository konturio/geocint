create index if not exists osm_roads_geom_idx on osm_roads using gist(geom);

-- Delete all facebook roads that have more than 50% intersection with 10m buffer from Open Street Map roads
explain
delete from facebook_roads a
using osm_roads b
where st_intersects(a.geom, b.geom) and
      st_length(ST_intersection(a.geom, st_buffer(b.geom::geography, 10)::geometry)) > 0.5 * st_length(a.geom);