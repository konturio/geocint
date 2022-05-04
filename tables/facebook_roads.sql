-- Create new table facebook_roads selecting only features that have less than 50% intersection with 10m buffer from Open Street Map roads
-- Facebook roads spec: https://github.com/facebookmicrosites/Open-Mapping-At-Facebook/wiki/Available-Countries
-- Note: The point of our filter is to remove the newly mapped roads that were mapped in OSM after the dataset was published by FB.

-- NOTE: facebook_roads need to be manually delete after facebook_roads_in refresh
create table if not exists facebook_roads as (
    select
        way_fbid,
        f.highway_tag as highway,
        f.geom as geom
    from facebook_roads_in
);

create table if not exists facebook_roads_last_filtered as (
    select '2019-01-01 00:00:00'::timestamp as ts
);

drop table if exists osm_roads_increment;
create table osm_roads_increment as (
    select geom from osm_roads_with_tz where ts > (select ts from facebook_roads_last_filtered)
);
create index on osm_roads_increment using gist(geom);

delete from facebook_roads
using osm_roads_increment
where ST_Intersects(facebook_roads.geom, osm_roads_increment.geom);

update facebook_roads_last_filtered
set ts = (select max(ts) from osm_roads_increment);
