-- Filter ESA World Cover vy osm_roads to exclude them from population calculation
drop table if exists esa_world_cover_builtup_h3_in;
create table esa_world_cover_builtup_h3_in as (
    select e.*
    from esa_world_cover e
    left join osm_roads o
             on ST_Intersects(e.rast, o.geom)
    where o.osm_id is null
);

-- Calculate esa_world_cover_built_h3
drop table if exists esa_world_cover_builtup_h3;
create table esa_world_cover_builtup_h3 as (
    select h3,
           8          as resolution,
           sum(count) as count
    from (
             select h3_geo_to_h3(ST_Transform(geom, 4326)::point, 8) as h3,
                    count(val)                                       as count
             from (
                      select p.geom, p.val
                      from esa_world_cover_builtup_h3_in ,
                           ST_PixelAsCentroids(rast) p
                  ) z
             where val = 5
             group by 1
         ) x
    group by 1
);


drop table if exists esa_world_cover_builtup_h3_in;