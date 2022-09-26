drop table if exists tile_logs_h3;
create table tile_logs_h3 as (
    select h3_lat_lng_to_cell(ST_Transform(ST_Centroid(geom), 4326)::point, 8) as h3,
           8                                         as resolution,
           sum(view_count)                           as view_count
    from tile_stats_z17
    group by 1);
