-- Create new table facebook_roads selecting only features that have less than 50% intersection with 10m buffer from Open Street Map roads
drop table if exists facebook_roads;
create table facebook_roads as
select
       way_fbid,
       f.highway_tag         as highway,
       fgeom                 as geom
from facebook_roads_in f,
     ST_SetSRID(f.geom, 4326) as fgeom
left join osm_roads o
        on ST_Intersects(fgeom, o.geom)
             and ST_Length(ST_intersection(fgeom, ST_Buffer(o.geom::geography, 10)::geometry)) > 0.5 * ST_Length(fgeom)
where o.osm_id is null;
