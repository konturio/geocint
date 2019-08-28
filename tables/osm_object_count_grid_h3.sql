drop table if exists osm_object_count_grid_h3;
create table osm_object_count_grid_h3 as (
    select resolution,
           h3,
           count(*)                                                             as count,
           count(*) filter (where tags ? 'building')                            as building_count,
           sum(highway_length)                                                  as highway_length,
           count(*) filter (where tags ? 'amenity')                             as amenity_count,
           --count(*) filter (where tags ? 'highway')                             as highway_count,
           --count(*) filter (where tags ? 'natural')                             as natural_count,
           --count(*) filter (where tags ? 'landuse')                             as landuse_count,
           count(distinct osm_user)                                             as osm_users,
           to_timestamp(avg(extract(epoch from ts)))                            as avg_ts,
           max(ts)                                                              as max_ts,
           to_timestamp(percentile_cont(0.9) within group (order by ts_epoch )) as p90_ts
    from (
             select resolution,
                    h3,
                    extract(epoch from ts) as ts_epoch,
                    tags,
                    osm_user,
                    ts,
                    case
                        when tags ? 'highway' then ST_Length(geog)
                        else 0 end         as highway_length
             from osm,
                  ST_H3Bucket(geog) as hex
             order by 1, 2, 3
         ) z
         --where ST_Y(ST_Centroid(geog::geometry)) between -85 and 85
    group by 1, 2

);
create index on osm_object_count_grid_h3 (h3, resolution);
