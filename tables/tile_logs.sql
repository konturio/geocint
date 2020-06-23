drop table if exists tile_logs;
create table tile_logs
(
    tile_date  date,
    z          int,
    x          int,
    y          int,
    view_count int
);