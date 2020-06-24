set enable_hashjoin = off;
set enable_indexscan = off;
drop table if exists stat_h3_in;
create table stat_h3_in as (
    select
        coalesce(a.resolution, b.resolution, c.resolution, t.resolution) as resolution,
        coalesce(a.resolution, b.resolution, c.resolution, t.resolution) as zoom,
        coalesce(a.h3, b.h3, c.h3, t.h3) as h3,
        coalesce(a.count, 0) as count,
        coalesce(a.building_count, 0) as building_count,
        coalesce(a.highway_length, 0) as highway_length,
        coalesce(a.osm_users, 0) as osm_users,
        coalesce(b.population, 0) as population,
        coalesce(r.residential, 0) as residential,
        coalesce(c.gdp, 0) as gdp,
        coalesce(a.avg_ts, 0) as avg_ts,
        coalesce(a.max_ts, 0) as max_ts,
        coalesce(a.p90_ts, 0) as p90_ts,
        coalesce(u.local_hours, 0)::float as local_hours,
        coalesce(u.total_hours, 0)::float as total_hours,
        coalesce(t.view_count, 0) as view_count
    from
        osm_object_count_grid_h3       a
        full join kontur_population_h3 b on a.h3 = b.h3
        full join gdp_h3               c on b.h3 = c.h3
        left join user_hours_h3        u on u.h3 = a.h3
        left join residential_pop_h3   r on r.h3 = b.h3
        full join tile_logs_h3         t on a.h3 = t.h3
);

alter table stat_h3_in set (parallel_workers=32);

drop table if exists stat_h3;
create table stat_h3 as (
    select
        a.*,
        hex.area / 1000000.0 as area_km2,
        hex.geom as geom
    from
        stat_h3_in           a,
        ST_HexagonFromH3(h3) hex
);
drop table stat_h3_in;
vacuum analyze stat_h3;
create index on stat_h3 using gist (geom, zoom);


