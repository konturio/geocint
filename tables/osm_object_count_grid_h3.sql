drop table if exists osm_object_count_grid_h3;
create table osm_object_count_grid_h3 as (
    select resolution,
           h3,
           count(*)                                              as count,
           count(*) filter (where is_building)                   as building_count,
           sum(highway_length)                                   as highway_length,
           count(*) filter (where is_amenity)                    as amenity_count,
           count(distinct osm_user)                              as osm_users,
           avg(ts_epoch)                                         as avg_ts,
           max(ts_epoch)                                         as max_ts,
           percentile_cont(0.9) within group (order by ts_epoch) as p90_ts
    from (
             select resolution             as resolution,
                    h3                     as h3,
                    extract(epoch from ts) as ts_epoch,
                    tags ? 'amenity'       as is_amenity,
                    tags ? 'building'      as is_building,
                    osm_user               as osm_user,
                    case
                        when tags ? 'highway' then ST_Length(geog)
                        else 0
                        end                as highway_length
             from osm,
                  ST_H3Bucket(geog) as hex
             order by 1, 2, 3
         ) z
    group by 1, 2

);
create index on osm_object_count_grid_h3 (h3, resolution);
