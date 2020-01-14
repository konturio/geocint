drop table if exists osm_user_count_grid_h3;
create table osm_user_count_grid_h3 as (
    select resolution,
           h3,
           osm_user,
           count(*) as count,
           count(distinct hours) as hours
    from (
             select
                 resolution as resolution,
                 h3         as h3,
                 osm_user   as osm_user,
                 date_trunc('hour', ts) as hours
             from osm,
                  ST_H3Bucket(geog) as hex
             where ts > (select max(ts) - interval '2 years' from osm)
         ) z
    group by 1, 2, 3
);

drop table if exists osm_user_object_count;
create table osm_user_object_count as (
    select osm_user,
           sum(count) as count,
           max(count) as max_count,
           sum(hours) as hours,
           max(hours) as max_hours,
           count(*) as hex_count,
           resolution
    from osm_user_count_grid_h3
    group by osm_user, resolution
);

drop table if exists osm_user_count_grid_h3_normalized;
create table osm_user_count_grid_h3_normalized as (
    select g.resolution,
           h3,
           count(distinct g.osm_user)    as user_count,
           sum(g.count::float / u.count) as user_count_normalized
    from osm_user_count_grid_h3 g
             join osm_user_object_count u on g.osm_user = u.osm_user
        and g.resolution = u.resolution
    group by 1, 2
);

alter table osm_user_count_grid_h3_normalized
    set (parallel_workers = 32);