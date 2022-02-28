-- Extract pixels with built up values
drop table if exists esa_world_cover_builtup_h3_in;
create table esa_world_cover_builtup_h3_in as (
    select p.val as val,
           p.geom as geom
    from esa_world_cover e, ST_PixelAsPolygons(rast) p
    where p.val = 5;
);


-- Create geometry index in input table
drop index if exists esa_world_cover_builtup_h3_in_idx;
create index esa_world_cover_builtup_h3_in_idx on esa_world_cover_builtup_h3_in using gist(geom);


-- filter pixels by the osm_roads
drop table if exists esa_world_cover_builtup_h3_mid;
create table esa_world_cover_builtup_h3_mid as (
    select p.val,
           p.geom
    from esa_world_cover_builtup_h3_in as p
    left join osm_roads o
    on ST_Intersects(p.geom, o.geom)
    where o.osm_id is null
);

drop table if exists esa_world_cover_builtup_h3_in;

-- Calculate esa_world_cover_built_h3
drop table if exists esa_world_cover_builtup_h3;
create table esa_world_cover_builtup_h3 as (
    select h3,
           8          as resolution,
           sum(count) as count
    from (
             select h3_geo_to_h3(ST_Transform(st_centroid(geom), 4326)::point, 8) as h3,
                    count(val)                                       as count
             from esa_world_cover_builtup_h3_mid
             group by 1
         ) x
    group by 1
);

drop table if exists esa_world_cover_builtup_h3_mid;