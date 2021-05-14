set enable_hashagg = off;
drop table if exists stat_h3_in;
create table stat_h3_in as (
    select h3,
           resolution,
           resolution as zoom,
           coalesce(sum(count), 0) as count,
           coalesce(sum(count_6_months), 0) as count_6_months,
           coalesce(sum(building_count), 0) as building_count,
           coalesce(sum(building_count_6_months), 0) as building_count_6_months,
           coalesce(sum(total_building_count), 0) as total_building_count,
           coalesce(sum(highway_length), 0) as highway_length,
           coalesce(sum(highway_length_6_months), 0) as highway_length_6_months,
           coalesce(sum(osm_users), 0) as osm_users,
           coalesce(sum(population), 0) as population,
           coalesce(sum(residential), 0) as residential,
           coalesce(sum(gdp), 0) as gdp,
           max(min_ts) as min_ts,
           max(max_ts) as max_ts,
           avg(avgmax_ts) as avgmax_ts,
           coalesce(sum(local_hours), 0) as local_hours,
           coalesce(sum(total_hours), 0) as total_hours,
           coalesce(sum(view_count), 0) as view_count,
           coalesce(sum(wildfires), 0) as wildfires,
		   coalesce(sum(covid19_vaccines), 0) as covid19_vaccines,
		   coalesce(sum(covid19_cases), 0) as covid19_cases,
           coalesce(sum(covid19_confirmed), 0) as covid19_confirmed,
           coalesce(sum(population_v2), 0) as population_v2,
           1::float as one
    from (
             select h3, count as count, count_6_months as count_6_months, building_count as building_count,
                    building_count_6_months as building_count_6_months,  null::float as total_building_count,
                    highway_length as highway_length, highway_length_6_months as highway_length_6_months, osm_users as osm_users,
                    null::float as population, null::float as residential, null::float as gdp, min_ts as min_ts, max_ts as max_ts,
                    avgmax_ts as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, null::float as covid19_vaccines, null::float as covid19_cases,
                    null::float as covid19_confirmed, null::float as population_v2, resolution
             from osm_object_count_grid_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, population as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, null::float as covid19_vaccines, null::float as covid19_cases,
                    null::float as covid19_confirmed, null::float as population_v2, resolution
             from kontur_population_h3
             union all
             select h3, null::float as count, null::float as count_6_months,null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, gdp::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, null::float as covid19_vaccines, null::float as covid19_cases,
                    null::float as covid19_confirmed, null::float as population_v2, resolution
             from gdp_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, local_hours as local_hours, total_hours as total_hours, null::float as view_count,
                    null::float as wildfires, null::float as covid19_vaccines, null::float as covid19_cases,
                    null::float as covid19_confirmed, null::float as population_v2, h3_get_resolution(h3) as resolution
             from user_hours_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, null::float as covid19_vaccines, null::float as covid19_cases,
                    null::float as covid19_confirmed, null::float as population_v2, h3_get_resolution(h3) as resolution
             from residential_pop_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, view_count::float as view_count,
                    null::float as wildfires, null::float as covid19_vaccines, null::float as covid19_cases,
                    null::float as covid19_confirmed, null::float as population_v2, resolution
             from tile_logs_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, building_count as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, null::float as covid19_vaccines, null::float as covid19_cases,
                    null::float as covid19_confirmed, null::float as population_v2, resolution
             from building_count_grid_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    wildfires as wildfires, null::float as covid19_vaccines, null::float as covid19_cases,
                    null::float as covid19_confirmed, null::float as population_v2, resolution
             from global_fires_stat_h3
			 union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, vaccine_value as covid19_vaccines, null::float as covid19_cases,
                    null::float as covid19_confirmed, null::float as population_v2, resolution
             from covid19_vaccine_accept_us_counties_h3
			 union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, null::float as covid19_vaccines, covid19_cases as covid19_cases,
                    null::float as covid19_confirmed, null::float as population_v2, resolution
             from covid19_cases_us_counties_h3
        	 union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, null::float as covid19_vaccines, null::float as covid19_cases,
                    confirmed as covid19_confirmed, null::float as population_v2, resolution
             from covid19_dithered
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, null::float as covid19_vaccines, null::float as covid19_cases,
                    null::float as covid19_confirmed, population as population_v2, resolution
             from kontur_population_h3_v2
        ) z
    group by 2, 1
);

alter table stat_h3_in
    set (parallel_workers=32);

drop table if exists stat_h3;
create table stat_h3 as (
    select a.*,
           (coalesce(b.avg_slope,0))::float as avg_slope,
           (coalesce(cf.forest_area,0))::float as forest,
           (coalesce(nd.avg_ndvi,0))::float as avg_ndvi,
           hex.area / 1000000.0 as area_km2,
           hex.geom as geom
    from stat_h3_in           a
         left join gebco_2020_slopes_h3 b on (a.h3 = b.h3)
         left join copernicus_forest_h3 cf on (a.h3 = cf.h3)
         left join ndvi_2019_06_10_h3 nd on (a.h3 = nd.h3),
         ST_HexagonFromH3(a.h3) hex
);
drop table stat_h3_in;
vacuum analyze stat_h3;
create index on stat_h3 using gist (geom, zoom);
create index stat_h3_brin_all on stat_h3 using brin
    (
     area_km2, building_count_6_months, covid19_vaccines, max_ts, population,
     total_hours, avgmax_ts, count, forest, highway_length, min_ts, residential,
     view_count, avg_slope, count_6_months, gdp, highway_length_6_months, one, resolution, wildfires,
     building_count, covid19_cases, geom, local_hours, osm_users, total_building_count, avg_ndvi, covid19_confirmed,
     population_v2, zoom
    );