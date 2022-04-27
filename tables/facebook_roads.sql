-- Create new table facebook_roads selecting only features that have less than 50% intersection with 10m buffer from Open Street Map roads
-- Facebook roads spec: https://github.com/facebookmicrosites/Open-Mapping-At-Facebook/wiki/Available-Countries
-- Note: The point of our filter is to remove the newly mapped roads that were mapped in OSM after the dataset was published by FB.
drop table if exists facebook_roads;
create table facebook_roads as
select
       way_fbid,
       f.highway_tag         as highway,
       f.geom
from facebook_roads_in f
left join osm_roads o
        on ST_Intersects(f.geom, o.geom)
             and ST_Length(
             	ST_Intersection(
             		f.geom, ST_Buffer(o.geom::geography, 10, 'endcap=flat join=bevel')::geometry
             	    -- `endcap=flat join=bevel` lessens points in buffer geom
             	)) > 0.5 * ST_Length(f.geom)
where o.osm_id is null;
