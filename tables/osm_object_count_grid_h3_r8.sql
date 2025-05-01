drop table if exists osm_object_count_grid_h3_r8;
create table osm_object_count_grid_h3_r8 as (
    select 8::int                                                as resolution,
           h3                                                    as h3,
           count(*)                                              as count,
           count(*) filter (where last_6_months)                 as count_6_months,
           count(*) filter (where is_building)                   as building_count,
           count(*) filter (where is_building and last_6_months) as building_count_6_months,
           count(distinct z.osm_user)                            as osm_users,
           min(ts_epoch)                                         as min_ts,
           max(ts_epoch)                                         as max_ts,
           max(ts_epoch)                                         as avgmax_ts,
           array_agg(distinct z.osm_user)                        as osm_users_array
    from (
             select
                    h3_lat_lng_to_cell(ST_PointOnSurface(geog::geometry)::point, 8) as h3,
                    extract(epoch from ts) as ts_epoch,
                    ts                     as ts,
                    osm_user               as osm_user,
                    ((tags ? 'building') and ((tags -> 'building') != '"no"')) as is_building,
                    ts > (select (meta -> 'data' -> 'timestamp' ->> 'last')::timestamptz
                          from osm_meta) - interval '6 months' as last_6_months
             from osm
             order by 1
         ) z
    group by h3
);

create index on osm_object_count_grid_h3 (h3);
