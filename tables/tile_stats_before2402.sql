drop table if exists tile_stats_before2402;
create table tile_stats_before2402 as (
    select z,
           x,
           y,
           avg(view_count) as view_avg
    from tile_logs_before2402
    group by 1, 2, 3, 4
);

drop table if exists tile_stats_z17_before2402 tablespace evo4tb;
create table tile_stats_z17_before2402 as (
    select 17                               as z,
           nx                               as x,
           ny                               as y,
           avg(t.view_avg / 4 ^ (17 - z)) as view_avg
    from tile_stats_before2402 t,
         generate_series((t.x * 2 ^ (17 - z))::int, ((t.x + 1) * 2 ^ (17 - z) - 1)::int) nx,
         generate_series((t.y * 2 ^ (17 - z))::int, ((t.y + 1) * 2 ^ (17 - z) - 1)::int) ny
    where z <= 17
      and z > 13
    group by 1, 2, 3
    union all
    select z, x, y, view_avg
    from tile_stats_before2402
    where z > 17
);

create index on tile_stats_z17_before2402 using btree (z, x, y);
