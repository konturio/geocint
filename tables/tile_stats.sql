drop table if exists tile_stats;
create table tile_stats as (
    select z,
           x,
           y,
           geom,
           sum(view_count) as view_count
    from tile_logs
    group by 1, 2, 3, 4
);

drop table if exists tile_stats_z17;
create table tile_stats_z17 as (
    select 17                               as z,
           nx                               as x,
           ny                               as y,
           sum(t.view_count / 4 ^ (17 - z)) as view_count,
           ST_TileEnvelope(17, nx, ny)      as geom
    from tile_stats t,
         generate_series((t.x * 2 ^ (17 - z))::int, ((t.x + 1) * 2 ^ (17 - z) - 1)::int) nx,
         generate_series((t.y * 2 ^ (17 - z))::int, ((t.y + 1) * 2 ^ (17 - z) - 1)::int) ny
    where z <= 17
      and z > 13
    group by 1, 2, 3
    union all
    select z, x, y, view_count, geom
    from tile_stats
    where z > 17
);

create index on tile_stats_z17 using brin (z, geom);
