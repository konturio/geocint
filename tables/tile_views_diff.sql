drop table if exists tile_views_diff;
create table tile_views_diff as (
    select b.z,
           b.x,
           b.y,
           coalesce(a.view_avg, 0) - b.view_avg as view_avg
    from tile_stats_z17_before2402 b
             left join tile_stats_z17_after2402 a
                       on (b.z, b.x, b.y) = (a.z, a.x, a.y)
);

drop table if exists tile_views_diff_h3;
create table tile_views_diff_h3 as (
    select h3_geo_to_h3(ST_Transform(ST_Centroid(ST_TileEnvelope(z, x, y)), 4326), 8) as h3,
           8                                                                          as resolution,
           avg(view_avg)                                                              as view_avg
    from tile_views_diff
    group by 1);
