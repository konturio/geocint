-- Create new table facebook_roads selecting only features that have less than 50% intersection with 10m buffer from Open Street Map roads
-- Facebook roads spec: https://github.com/facebookmicrosites/Open-Mapping-At-Facebook/wiki/Available-Countries
-- Note: The point of our filter is to remove the newly mapped roads that were mapped in OSM after the dataset was published by FB.

-- NOTE: facebook_roads need to be manually delete after facebook_roads_in refresh

drop table if exists osm_roads_increment;
create table osm_roads_increment as (
    select ts, geom
    from osm_roads
    where ts > (
        select ts
        from facebook_roads_last_filtered
    )
    order by ts desc
);
create index on osm_roads_increment using gist (geom);

create table if not exists facebook_roads  as (
    select geom
    from facebook_roads_in
);

drop table if exists facebook_roads_new;
create table facebook_roads_new as (
    select f.geom
    from facebook_roads f
     left outer join lateral (
        select i.geom
        from osm_roads_increment i,
             ST_Length(
                     ST_Intersection(
                             f.geom,
                             ST_Buffer(i.geom::geography, 10, 'endcap=flat join=bevel')::geometry
                             -- `endcap=flat join=bevel` lessens points in buffer geom
                         )
                 ) intersection_length
        where ST_Intersects(f.geom, i.geom)
          and intersection_length > ST_Length(f.geom) / 2
        ) t
        on true
    where t.geom is null
);
