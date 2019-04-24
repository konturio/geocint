drop table if exists osm_object_count_grid_1000;
create table osm_object_count_grid_1000 as (
    select
        ST_Pixel(geog::geometry, 7)                          as geom,
        count(*)                                             as count,
        count(*) filter (where tags ? 'building')            as building_count,
        count(*) filter (where tags ? 'highway')             as highway_count,
        sum(ST_Length(geog)) filter (where tags ? 'highway') as highway_length,
        count(*) filter (where tags ? 'amenity')             as amenity_count,
        count(*) filter (where tags ? 'natural')             as natural_count,
        count(*) filter (where tags ? 'landuse')             as landuse_count
    from
        osm
    where
        ST_Y(ST_Centroid(geog::geometry)) between -85 and 85
    group by 1
    order by 1
);
create index on osm_object_count_grid_1000 using gist (geom);