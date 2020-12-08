set enable_hashagg = off;
drop table if exists stat_h3_in;
create table stat_h3_in as (
    select h3,
           resolution,
           resolution as zoom,
           coalesce(sum(count), 0) as count,
           coalesce(sum(building_count), 0) as building_count,
           coalesce(sum(total_building_count), 0) as total_building_count,
           coalesce(sum(highway_length), 0) as highway_length,
           coalesce(sum(osm_users), 0) as osm_users,
           coalesce(sum(population), 0) as population,
           coalesce(sum(residential), 0) as residential,
           coalesce(sum(gdp), 0) as gdp,
           avg(avg_ts) as avg_ts,
           max(max_ts) as max_ts,
           max(p90_ts) as p90_ts,
           coalesce(sum(local_hours), 0) as local_hours,
           coalesce(sum(total_hours), 0) as total_hours,
           coalesce(sum(view_count), 0) as view_count,
           coalesce(sum(wildfires), 0) as wildfires,
           1::float as one
    from (
             select h3, count as count, building_count as building_count, null::float as total_building_count, highway_length as highway_length,
                    osm_users as osm_users, null::float as population, null::float as residential, null::float as gdp,
                    avg_ts as avg_ts, max_ts as max_ts, p90_ts as p90_ts, null::float as local_hours,
                    null::float as total_hours, null::float as view_count, null::float as wildfires, resolution
             from osm_object_count_grid_h3
             union all
             select h3, null::float as count, null::float as building_count, null::float as total_building_count, null::float as highway_length,
                    null::float as osm_users, population as population, null::float as residential, null::float as gdp,
                    null::float as avg_ts, null::float as max_ts, null::float as p90_ts, null::float as local_hours,
                    null::float as total_hours, null::float as view_count, null::float as wildfires, resolution
             from kontur_population_h3
             union all
             select h3, null::float as count, null::float as building_count, null::float as total_building_count, null::float as highway_length,
                    null::float as osm_users, null::float as population, null::float as residential, gdp::float as gdp,
                    null::float as avg_ts, null::float as max_ts, null::float as p90_ts, null::float as local_hours,
                    null::float as total_hours, null::float as view_count, null::float as wildfires, resolution
             from gdp_h3
             union all
             select h3, null::float as count, null::float as building_count, null::float as total_building_count, null::float as highway_length,
                    null::float as osm_users, null::float as population, null::float as residential, null::float as gdp,
                    null::float as avg_ts, null::float as max_ts, null::float as p90_ts, local_hours as local_hours,
                    total_hours as total_hours, null::float as view_count, null::float as wildfires, h3_get_resolution(h3) as resolution
             from user_hours_h3
             union all
             select h3, null::float as count, null::float as building_count, null::float as total_building_count, null::float as highway_length,
                    null::float as osm_users, null::float as population, null::float as residential, null::float as gdp,
                    null::float as avg_ts, null::float as max_ts, null::float as p90_ts, null::float as local_hours,
                    null::float as total_hours, null::float as view_count, null::float as wildfires, h3_get_resolution(h3) as resolution
             from residential_pop_h3
             union all
             select h3, null::float as count, null::float as building_count, null::float as total_building_count, null::float as highway_length,
                    null::float as osm_users, null::float as population, null::float as residential, null::float as gdp,
                    null::float as avg_ts, null::float as max_ts, null::float as p90_ts, null::float as local_hours,
                    null::float as total_hours, view_count::float as view_count, null::float as wildfires, resolution
             from tile_logs_h3
             union all
             select h3, null::float as count, null::float as building_count, building_count as total_building_count, null::float as highway_length,
                    null::float as osm_users, null::float as population, null::float as residential, null::float as gdp,
                    null::float as avg_ts, null::float as max_ts, null::float as p90_ts, null::float as local_hours,
                    null::float as total_hours, null::float as view_count, null::float as wildfires, resolution
             from building_count_grid_h3
             union all
             select h3, null::float as count, null::float as building_count, null::float as total_building_count, null::float as highway_length,
                    null::float as osm_users, null::float as population, null::float as residential, null::float as gdp,
                    null::float as avg_ts, null::float as max_ts, null::float as p90_ts, null::float as local_hours,
                    null::float as total_hours, null::float as view_count, wildfires as wildfires, resolution
             from global_fires_stat_h3
         ) z
    group by 2, 1
);

alter table stat_h3_in
    set (parallel_workers=32);

drop table if exists stat_h3;
create table stat_h3 as (
    select a.*,
           hex.area / 1000000.0 as area_km2,
           hex.geom as geom
    from stat_h3_in           a,
         ST_HexagonFromH3(h3) hex
);
drop table stat_h3_in;
vacuum analyze stat_h3;
create index on stat_h3 using gist (geom, zoom);
