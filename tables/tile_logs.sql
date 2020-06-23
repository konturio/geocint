drop table if exists tile_logs;
create table tile_logs
(
    tile_date  timestamptz,
    z          int,
    x          int,
    y          int,
    view_count int
);