alter table tile_logs
    set (parallel_workers = 32);

drop table if exists tile_logs_h3;
create table tile_logs_h3 as (
    select h3_geo_to_h3(ST_Transform(ST_Centroid(geom), 4326)::point, 8) as h3,
           8                                         as resolution,
           sum(view_count)                           as view_count
    from tile_stats_z17
    group by 1);

alter table tile_logs_h3
    set (parallel_workers = 32);

do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into tile_logs_h3 (h3, view_count, resolution)
                select h3_to_parent(h3) as h3, sum(view_count) as view_count, (res - 1) as resolution
                from tile_logs_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;
