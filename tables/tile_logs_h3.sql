alter table tile_logs
    set (parallel_workers = 32);

drop table if exists tile_logs_h3;
create table tile_logs_h3 as (
    select
           h3_geo_to_h3(ST_Centroid(geom)::point, 8) as h3,
           8                                         as resolution,
           sum(view_count)                           as view_count
    from tile_logs t
    where z >= 17
    group by 1);
