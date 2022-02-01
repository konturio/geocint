-- Create new table facebook_roads selecting only features that have less than 50% intersection with 10m buffer from Open Street Map roads
drop table if exists facebook_roads;
create table facebook_roads as
select
       row_number() over()                                  as id,
       f.highway_tag                                        as highway,
       ST_SetSRID(f.geom, 4326)::geometry(Linestring, 4326) as geom
from facebook_roads_in f
left join osm_roads o
    on ST_Intersects(f.geom, o.geom)
           and ST_Length(ST_intersection(f.geom, ST_Buffer(o.geom::geography, 10)::geometry)) > 0.5 * ST_Length(f.geom)
where o.osm_id is null;


-- Drop temporary tables
drop table if exists facebook_roads_in;