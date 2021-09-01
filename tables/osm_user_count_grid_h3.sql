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
             where ts > (select (meta -> 'data' -> 'timestamp' ->> 'last')::timestamptz
                          from osm_meta) - interval '2 years'
         ) z
    group by 1, 2, 3
);

create index on osm_user_count_grid_h3 (h3);

