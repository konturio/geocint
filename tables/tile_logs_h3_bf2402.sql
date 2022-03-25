drop table if exists tile_logs_bf2402_h3;
create table tile_logs_bf2402_h3 as (
    select h3_geo_to_h3(ST_Transform(ST_Centroid(ST_TileEnvelope(z, x, y)), 4326), 8) as h3,
           8                                                                          as resolution,
           sum(view_count_bf2402)                                                     as view_count_bf2402
    from tile_stats_z17_bf2402
    group by 1);
