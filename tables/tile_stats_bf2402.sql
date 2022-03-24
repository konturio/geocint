drop table if exists tile_stats_bf2402;
create table tile_stats_bf2402 as (
    select z,
           x,
           y,
           sum(view_count) as view_count_bf2402
    from tile_logs_bf2402
    group by 1, 2, 3
);

drop table if exists tile_stats_z17_bf2402;
create table tile_stats_z17_bf2402 tablespace evo4tb as (
    select 17                               as z,
           nx                               as x,
           ny                               as y,
           sum(t.view_count_bf2402 / 4 ^ (17 - z)) as view_count_bf2402
    from tile_stats_bf2402 t,
         generate_series((t.x * 2 ^ (17 - z))::int, ((t.x + 1) * 2 ^ (17 - z) - 1)::int) nx,
         generate_series((t.y * 2 ^ (17 - z))::int, ((t.y + 1) * 2 ^ (17 - z) - 1)::int) ny
    where z <= 17
      and z > 13
    group by 1, 2, 3
    union all
    select z, x, y, view_count_bf2402
    from tile_stats_bf2402
    where z > 17
) ;

create index on tile_stats_z17_bf2402 using btree (z, x, y);