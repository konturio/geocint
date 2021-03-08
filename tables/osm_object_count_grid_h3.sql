drop table if exists osm_object_count_grid_h3;
create table osm_object_count_grid_h3 as (
    select 8::int                                                as resolution,
           h3                                                    as h3,
           count(*)                                              as count,
           count(*) filter (where last_6_months)                 as count_6_months,
           count(*) filter (where is_building)                   as building_count,
           count(*) filter (where is_building and last_6_months) as building_count_6_months,
           sum(highway_length)                                   as highway_length,
           sum(highway_length) filter (where last_6_months)      as highway_length_6_months,
           count(distinct z.osm_user)                            as osm_users,
           min(ts_epoch)                                         as min_ts,
           max(ts_epoch)                                         as max_ts,
           max(ts_epoch)                                         as avgmax_ts,
           array_agg(distinct z.osm_user)                        as osm_users_array
    from (
             select
                    h3_geo_to_h3(ST_PointOnSurface(geog::geometry)::point, 8) as h3,
                    extract(epoch from ts) as ts_epoch,
                    ts                     as ts,
                    osm_user               as osm_user,
                    ((tags ? 'building') and ((tags -> 'building') != '"no"')) as is_building,
                    ts > (select (meta -> 'data' -> 'timestamp' ->> 'last')::timestamptz
                          from osm_meta) - interval '6 months' as last_6_months,
                    case
                        when tags ? 'highway' then ST_Length(geog)
                        else 0
                        end                as highway_length
             from osm
             order by 1
         ) z
    group by h3
);

do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                -- aggregation below is split into two parts: first one generates correct sum/avg aggregates
                -- second one generates group by aggregation
                -- this can be done as two inserts as the values are going to be regrouped together in stat_h3 calculation
                insert into osm_object_count_grid_h3 (resolution, h3, count, count_6_months, building_count,
                                                      building_count_6_months, highway_length, highway_length_6_months,
                                                      min_ts, max_ts, avgmax_ts)
                select (res - 1) as resolution,
                       h3_to_parent(h3) as h3,
                       sum(count) as count,
                       sum(count_6_months) as count_6_months,
                       sum(building_count) as building_count,
                       sum(building_count_6_months) as building_count_6_months,
                       sum(highway_length) as highway_length,
                       sum(highway_length_6_months) as highway_length_6_months,
                       min(min_ts) as min_ts,
                       max(max_ts) as max_ts,
                       avg(avgmax_ts) as avgmax_ts
                from osm_object_count_grid_h3
                where resolution = res
                group by 2;

                insert into osm_object_count_grid_h3 (resolution, h3, osm_users,osm_users_array)
                select (res - 1) as resolution,
                       h3_to_parent(h3) as h3,
                       count(distinct osm_user) as osm_users,
                       array_agg(distinct osm_user) as osm_users_array
                from osm_object_count_grid_h3, unnest(osm_users_array) as osm_user
                where resolution = res
                group by 2;
                res = res - 1;
            end loop;
    end;
$$;
