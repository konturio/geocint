drop table if exists facebook_roads;
create table facebook_roads as
select
       way_fbid,
       f.highway_tag         as highway,
       f.geom
from facebook_roads_in f
where ST_NPoints(geom) = 2; -- ai roads are segments. osm roads are lines.
