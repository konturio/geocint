drop table if exists user_hours_h3;

create table user_hours_h3 as (
    select h3,
        count(uc.hours) FILTER (
            WHERE exists(select
                         from osm_local_active_users au
                         where au.osm_user = uc.osm_user
                           and ST_DWithin(geog, ST_Transform(hex.geom, 4326)::geography, 50000))
            )               as local_hours,
        count(uc.hours)     as total_hours
    from osm_user_count_grid_h3 uc,
        ST_HexagonFromH3(uc.h3) hex
    group by h3
);

create index on user_hours_h3(h3);