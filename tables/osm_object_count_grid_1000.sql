drop table if exists osm_object_count_grid_1000;
create table osm_object_count_grid_1000 as (
    select
	zoom, 
        ST_Pixel(geog::geometry, zoom)                          as geom,
        count(*)                                             as count,
        count(*) filter (where tags ? 'building')            as building_count,
        count(*) filter (where tags ? 'highway')             as highway_count,
        sum(ST_Length(geog)) filter (where tags ? 'highway') as highway_length,
        count(*) filter (where tags ? 'amenity')             as amenity_count,
        count(*) filter (where tags ? 'natural')             as natural_count,
        count(*) filter (where tags ? 'landuse')             as landuse_count,
        count(distinct osm_user)                             as osm_users,
	to_timestamp(avg(extract(epoch from ts)))            as avg_ts,
        max(ts)                                              as max_ts
--        to_timestamp(percentile_cont(0.9) within group (order by extract(epoch from ts))) as p90_ts
    from
        osm,
	generate_series(7,7) zoom
    where
        ST_Y(ST_Centroid(geog::geometry)) between -85 and 85
    group by 1, 2
    order by 1, 2
);
create index on osm_object_count_grid_1000 using gist (geom, zoom);
