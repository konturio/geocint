set enable_hashagg = off;
drop table if exists stat_h3_in;
create table stat_h3_in tablespace evo4tb as (
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
           coalesce(sum(population_prev), 0) as population_prev,
           coalesce(sum(industrial_area), 0) as industrial_area,
           coalesce(sum(volcanos_count), 0) as volcanos_count,
           coalesce(sum(pop_under_5_total), 0) as pop_under_5_total,
           coalesce(sum(pop_over_65_total), 0) as pop_over_65_total,
           coalesce(sum(poverty_families_total), 0) as poverty_families_total,
           coalesce(sum(pop_disability_total), 0) as pop_disability_total,
           coalesce(sum(pop_not_well_eng_speak), 0) as pop_not_well_eng_speak,
           coalesce(sum(pop_without_car), 0) as pop_without_car,
           coalesce(sum(populated_area) / 1000000.0, 0) as populated_area_km2,
           coalesce(sum(man_distance_to_fire_brigade), 0) as man_distance_to_fire_brigade,
           coalesce(sum(man_distance_to_hospital), 0) as man_distance_to_hospital,
           coalesce(sum(total_road_length), 0) as total_road_length,
           coalesce(sum(foursquare_places_count), 0) as foursquare_places_count,
           coalesce(sum(foursquare_visits_count), 0) as foursquare_visits_count,
           coalesce(sum(view_count_bf2402), 0) as view_count_bf2402,
           coalesce(sum(eatery_count), 0) as eatery_count,
           coalesce(sum(food_shops_count), 0) as food_shops_count,
           coalesce(sum(man_distance_to_bomb_shelters), 0) as man_distance_to_bomb_shelters,
           coalesce(sum(man_distance_to_charging_stations), 0) as man_distance_to_charging_stations,
           1::float as one
    from (
             select h3, count as count, count_6_months as count_6_months, building_count as building_count,
                    building_count_6_months as building_count_6_months,  null::float as total_building_count,
                    null::float as highway_length, null::float as highway_length_6_months, osm_users as osm_users,
                    null::float as population, null::float as residential, null::float as gdp, min_ts as min_ts, max_ts as max_ts,
                    avgmax_ts as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count,
                    null::float as pop_under_5_total, null::float as pop_over_65_total, null::float as poverty_families_total,
                    null::float as pop_disability_total, null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from osm_object_count_grid_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, population as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count,
                    null::float as pop_under_5_total, null::float as pop_over_65_total, null::float as poverty_families_total,
                    null::float as pop_disability_total, null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from kontur_population_h3
             union all
             select h3, null::float as count, null::float as count_6_months,null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, gdp::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires,
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count,
                    null::float as pop_under_5_total, null::float as pop_over_65_total, null::float as poverty_families_total,
                    null::float as pop_disability_total, null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from gdp_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, local_hours as local_hours, total_hours as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count,
                    null::float as pop_under_5_total, null::float as pop_over_65_total, null::float as poverty_families_total,
                    null::float as pop_disability_total, null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, h3_get_resolution(h3) as resolution
             from user_hours_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count,
                    null::float as pop_under_5_total, null::float as pop_over_65_total, null::float as poverty_families_total,
                    null::float as pop_disability_total, null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, h3_get_resolution(h3) as resolution
             from residential_pop_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, view_count::float as view_count,
                    null::float as wildfires,
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count,
                    null::float as pop_under_5_total, null::float as pop_over_65_total, null::float as poverty_families_total,
                    null::float as pop_disability_total, null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from tile_logs_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, building_count as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires,
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count,
                    null::float as pop_under_5_total, null::float as pop_over_65_total, null::float as poverty_families_total,
                    null::float as pop_disability_total, null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from building_count_grid_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    wildfires::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count,
                    null::float as pop_under_5_total, null::float as pop_over_65_total, null::float as poverty_families_total,
                    null::float as pop_disability_total, null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from global_fires_stat_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires,
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count,
                    null::float as pop_under_5_total, null::float as pop_over_65_total, null::float as poverty_families_total,
                    null::float as pop_disability_total, null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from covid19_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires,
                    population as population_prev, null::float as industrial_area, null::float as volcanos_count,
                    null::float as pop_under_5_total, null::float as pop_over_65_total, null::float as poverty_families_total,
                    null::float as pop_disability_total, null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from kontur_population_v3_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from osm_landuse_industrial_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, volcanos_count::float, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from osm_volcanos_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count, pop_under_5_total,
                    pop_over_65_total, poverty_families_total, pop_disability_total, pop_not_well_eng_speak, pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from us_census_tracts_stats_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, man_distance as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from isodist_fire_stations_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, man_distance as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from isodist_hospitals_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    total_road_length as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from total_road_length_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_v2, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from foursquare_places_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_v2, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    foursquare_visits_count::float, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from foursquare_visits_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_v2, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car, null::float as populated_area, 
                    null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from tile_logs_bf2402_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_v2, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car, null::float as populated_area, 
                    null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from osm_road_segments_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_v2, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car, null::float as populated_area, 
                    null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from osm_road_segments_6_months_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_v2, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car, null::float as populated_area,
                    null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    eatery_count::float, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from osm_places_eatery_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_v2, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car, null::float as populated_area,
                    null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, food_shops_count::float, null::float as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from osm_places_food_shops_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, man_distance as man_distance_to_bomb_shelters,
                    null::float as man_distance_to_charging_stations, resolution
             from isodist_bomb_shelters_h3
             union all
             select h3, null::float as count, null::float as count_6_months, null::float as building_count,
                    null::float as building_count_6_months, null::float as total_building_count, null::float as highway_length,
                    null::float as highway_length_6_months, null::float as osm_users, null::float as population,
                    null::float as residential, null::float as gdp, null::float as min_ts, null::float as max_ts,
                    null::float as avgmax_ts, null::float as local_hours, null::float as total_hours, null::float as view_count,
                    null::float as wildfires, 
                    null::float as population_prev, null::float as industrial_area, null::float as volcanos_count, null::float as pop_under_5_total,
                    null::float as pop_over_65_total, null::float as poverty_families_total, null::float as pop_disability_total,
                    null::float as pop_not_well_eng_speak, null::float as pop_without_car,
                    null::float as populated_area, null::float as man_distance_to_fire_brigade, null::float as man_distance_to_hospital,
                    null::float as total_road_length, null::float as foursquare_places_count,
                    null::float as foursquare_visits_count, null::float as view_count_bf2402,
                    null::float as eatery_count, null::float as food_shops_count, null::float as man_distance_to_bomb_shelters,
                    man_distance as man_distance_to_charging_stations, resolution
             from isodist_charging_stations_h3
        ) z
    group by 2, 1
);


drop table if exists stat_h3;
create table stat_h3 tablespace evo4tb as (
    select a.h3,
           a.zoom,
           a.population,
           hex.area / 1000000.0 as area_km2,
           a.view_count,
           a.count,
           a.one,
           a.populated_area_km2,
           a.building_count,
           a.highway_length / 1000.0 as highway_length,
           a.total_road_length / 1000.0 as total_road_length,
           a.local_hours,
           a.total_hours,
           a.resolution,
           a.avgmax_ts,
           a.man_distance_to_fire_brigade,
           a.view_count_bf2402,
           (coalesce(pf.days_mintemp_above_25c_1c, 0))::float as days_mintemp_above_25c_1c,
           a.total_building_count,
           a.count_6_months,
           a.building_count_6_months,
           a.highway_length_6_months / 1000.0 as highway_length_6_months,
           a.osm_users,
           a.residential,
           a.gdp,
           a.min_ts,
           a.max_ts,
           a.wildfires,
           a.population_prev,
           a.industrial_area,
           a.volcanos_count,
           a.pop_under_5_total,
           a.pop_over_65_total,
           a.poverty_families_total,
           a.pop_disability_total,
           a.pop_not_well_eng_speak,
           a.pop_without_car,
           a.man_distance_to_hospital,
           a.man_distance_to_bomb_shelters, 
           a.man_distance_to_charging_stations,
           a.foursquare_places_count,
           a.foursquare_visits_count,
           a.eatery_count,
           a.food_shops_count,
           (coalesce(ms.mapswipe_area, 0))::float as mapswipe_area_km2,
           (coalesce(gbc.avg_slope_gebco_2022, 0))::float as avg_slope_gebco_2022,
           (coalesce(gbc.avg_elevation_gebco_2022, 0))::float as avg_elevation_gebco_2022,
           (coalesce(cf.forest_area, 0))::float as forest,
           (coalesce(cf.evergreen_needle_leaved_forest, 0))::float as evergreen_needle_leaved_forest,
           (coalesce(cf.shrubs, 0))::float as shrubs,
           (coalesce(cf.herbage, 0))::float as herbage,
           (coalesce(cf.unknown_forest, 0))::float as unknown_forest,
           (coalesce(nd.avg_ndvi, 0))::float as avg_ndvi,
           (coalesce(pf.days_maxtemp_over_32c_1c, 0))::float as days_maxtemp_over_32c_1c,
           (coalesce(pf.days_maxtemp_over_32c_2c, 0))::float as days_maxtemp_over_32c_2c,
           (coalesce(pf.days_mintemp_above_25c_2c, 0))::float as days_mintemp_above_25c_2c,
           (coalesce(pf.days_maxwetbulb_over_32c_1c, 0))::float as days_maxwetbulb_over_32c_1c,
           (coalesce(pf.days_maxwetbulb_over_32c_2c, 0))::float as days_maxwetbulb_over_32c_2c,
           (coalesce(pf.mandays_maxtemp_over_32c_1c, 0))::float as mandays_maxtemp_over_32c_1c,
           (coalesce(rva.mhr_index, 0))::float as mhr_index,
           (coalesce(rva.mhe_index, 0))::float as mhe_index,
           (coalesce(rva.resilience_index, 0))::float as resilience_index,
           (coalesce(rva.coping_capacity_index, 0))::float as coping_capacity_index,
           (coalesce(rva.vulnerability_index, 0))::float as vulnerability_index,
           (coalesce(disaster_event_episodes_h3.hazardous_days_count, 0))::float as hazardous_days_count,
           (coalesce(disaster_event_episodes_h3.earthquake_days_count, 0))::float as earthquake_days_count,
           (coalesce(disaster_event_episodes_h3.wildfire_days_count, 0))::float as wildfire_days_count,
           (coalesce(disaster_event_episodes_h3.drought_days_count, 0))::float as drought_days_count,
           (coalesce(disaster_event_episodes_h3.cyclone_days_count, 0))::float as cyclone_days_count,
           (coalesce(disaster_event_episodes_h3.volcano_days_count, 0))::float as volcano_days_count,
           (coalesce(disaster_event_episodes_h3.flood_days_count, 0))::float as flood_days_count,
           (coalesce(facebook_medium_voltage_distribution_h3.powerlines, 0))::float as powerlines,
           (coalesce(nl.intensity, 0))::float as night_lights_intensity,
           (coalesce(gsa.gsa_ghi, 0))::float as gsa_ghi,
           (coalesce(wc_temp.worldclim_avg_temperature, 0))::float as worldclim_avg_temperature,
           (coalesce(wc_temp.worldclim_min_temperature, 0))::float as worldclim_min_temperature,
           (coalesce(wc_temp.worldclim_max_temperature, 0))::float as worldclim_max_temperature,
           (coalesce((wc_temp.worldclim_max_temperature - wc_temp.worldclim_min_temperature) , 0))::float as worldclim_amp_temperature,
           hex.geom as geom
    from stat_h3_in           a
         left join gebco_2022_h3 gbc on (a.h3 = gbc.h3)
         left join copernicus_forest_h3 cf on (a.h3 = cf.h3)
         left join pf_maxtemp_h3 pf on (a.h3 = pf.h3)
         left join ndvi_2019_06_10_h3 nd on (a.h3 = nd.h3)
         left join global_rva_h3 rva on (a.h3 = rva.h3)
         left join disaster_event_episodes_h3 on (a.h3 = disaster_event_episodes_h3.h3)
         left join facebook_medium_voltage_distribution_h3 on (a.h3 = facebook_medium_voltage_distribution_h3.h3)
         left join night_lights_h3 nl on (a.h3 = nl.h3)
         left join global_solar_atlas_h3 gsa on (a.h3 = gsa.h3)
         left join worldclim_temperatures_h3 wc_temp on (a.h3 = wc_temp.h3)
         left join mapswipe_hot_tasking_data_h3 ms on (a.h3 = ms.h3),
         ST_HexagonFromH3(a.h3) hex
);
drop table stat_h3_in;
vacuum analyze stat_h3;
create index on stat_h3 using gist (geom, zoom);
-- cannot create index with more than 32 columns, so create more indexes
create index stat_h3_brin_pt1 on stat_h3 using brin (
                                                     area_km2, populated_area_km2, population, count, building_count,
                                                     highway_length, resolution, zoom, geom, one, total_building_count,
                                                     max_ts, total_hours, avgmax_ts, forest,
                                                     evergreen_needle_leaved_forest, shrubs, herbage, unknown_forest,
                                                     min_ts, residential, view_count, count_6_months, total_road_length,
                                                     view_count_bf2402, mhr_index, mhe_index, resilience_index, 
                                                     coping_capacity_index, vulnerability_index, night_lights_intensity
    );

create index stat_h3_brin_pt2 on stat_h3 using brin (
                                                     gdp, highway_length_6_months, wildfires, avg_ndvi,building_count_6_months,
                                                     local_hours, osm_users, population_prev,
                                                     industrial_area, volcanos_count, pop_under_5_total,
                                                     pop_over_65_total, poverty_families_total, pop_disability_total,
                                                     pop_not_well_eng_speak, pop_without_car, mandays_maxtemp_over_32c_1c,
                                                     days_maxtemp_over_32c_1c, days_maxtemp_over_32c_2c,
                                                     days_mintemp_above_25c_1c, days_mintemp_above_25c_2c,
                                                     days_maxwetbulb_over_32c_1c, days_maxwetbulb_over_32c_2c,
                                                     man_distance_to_fire_brigade, man_distance_to_hospital,
                                                     foursquare_visits_count, foursquare_places_count, flood_days_count,
                                                     powerlines
    );

create index stat_h3_brin_pt3 on stat_h3 using brin (
                                                     eatery_count, food_shops_count, avg_elevation_gebco_2022,
                                                     avg_slope_gebco_2022, mapswipe_area_km2, gsa_ghi,
                                                     worldclim_avg_temperature, worldclim_min_temperature,
                                                     worldclim_max_temperature, worldclim_amp_temperature,
                                                     man_distance_to_bomb_shelters, man_distance_to_charging_stations
    );
