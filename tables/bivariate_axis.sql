drop function if exists calculate_axis_stops(text);
drop function if exists calculate_axis_stops(text, text);
create or replace function calculate_axis_stops(parameter1 text, parameter2 text)
    returns TABLE
    (
        min double precision,
        p25 double precision,
        p75 double precision,
        max double precision
    )
    language plpgsql
as
$$
declare
    select_query text;
begin
    select_query = 'select floor(min(' || parameter1 || ' / ' || parameter2 || '::double precision))   as min, ' ||
                   'percentile_disc(0.33) within group (order by ' || parameter1 || ' / ' || parameter2 ||
                   '::double precision)::double precision as p25, ' ||
                   'percentile_disc(0.66) within group (order by ' || parameter1 || ' / ' || parameter2 ||
                   '::double precision)::double precision as p75, ' ||
                   'ceil(max(' || parameter1 || ' / ' || parameter2 || '::double precision))   as max ' ||
                   'from stat_h3 ' ||
                   'where ' || parameter1 || ' != 0 and ' || parameter2 ||
                   ' != 0 and' ||
                   ' population > 0';
    -- population > 0 is needed because stat_h3 has 65% of hexagons in
    -- unpopulated areas that skew generated histogram to be less interesting in humanitarian context.
    return query execute select_query;
end;
$$
    stable
    parallel safe;

drop table if exists stat_h3_quality;
create table stat_h3_quality as (
    select *
    from
        (
            select
                h3_to_parent(a.h3) as h3_parent,
                avg(a.count) as agg_count,
                avg(a.count_6_months) as agg_count_6_months,
                avg(a.building_count) as agg_building_count,
                avg(a.building_count_6_months) as agg_building_count_6_months,
                avg(a.highway_length) as agg_highway_length,
                avg(a.highway_length_6_months) as agg_highway_length_6_months,
                avg(a.osm_users) as agg_osm_users,
                avg(a.population) as agg_population,
                avg(a.residential) as agg_residential,
                avg(a.gdp) as agg_gdp,
                avg(a.min_ts) as agg_min_ts,
                avg(a.max_ts) as agg_max_ts,
                avg(a.avgmax_ts) as agg_avgmax_ts,
                avg(a.local_hours) as agg_local_hours,
                avg(a.total_hours) as agg_total_hours,
                avg(a.view_count) as agg_view_count,
                avg(a.area_km2) as agg_area_km2,
                avg(a.populated_area_km2) as agg_populated_area_km2,
                avg(a.one) as agg_one,
                avg(a.total_building_count) as agg_total_building_count,
                avg(a.wildfires) as agg_wildfires,
                avg(a.covid19_vaccines) as agg_covid19_vaccines,
                avg(a.avg_slope) as agg_avg_slope,
                avg(a.avg_elevation) as agg_avg_elevation,
                avg(a.forest) as agg_forest,
                avg(a.avg_ndvi) as agg_avg_ndvi,
                avg(a.covid19_confirmed) as agg_covid19_confirmed,
                avg(a.population_prev) as agg_population_prev,
                avg(a.industrial_area) as agg_industrial_area,
                avg(a.volcanos_count) as agg_volcanos_count,
                avg(a.pop_under_5_total) as agg_pop_under_5_total,
                avg(a.pop_over_65_total) as agg_pop_over_65_total,
                avg(a.poverty_families_total) as agg_poverty_families_total,
                avg(a.pop_disability_total) as agg_pop_disability_total,
                avg(a.pop_not_well_eng_speak) as agg_pop_not_well_eng_speak,
                avg(a.pop_without_car) as agg_pop_without_car,
                avg(a.evergreen_needle_leaved_forest) as agg_evergreen_needle_leaved_forest,
                avg(a.shrubs) as agg_shrubs,
                avg(a.herbage) as agg_herbage,
                avg(a.unknown_forest) as agg_unknown_forest,
                avg(a.days_maxtemp_over_32c_1c) as agg_days_maxtemp_over_32c_1c,
                avg(a.days_maxtemp_over_32c_2c) as agg_days_maxtemp_over_32c_2c,
                avg(a.days_mintemp_above_25c_1c) as agg_days_mintemp_above_25c_1c,
                avg(a.days_mintemp_above_25c_2c) as agg_days_mintemp_above_25c_2c,
                avg(a.days_maxwetbulb_over_32c_1c) as agg_days_maxwetbulb_over_32c_1c,
                avg(a.days_maxwetbulb_over_32c_2c) as agg_days_maxwetbulb_over_32c_2c,
                avg(a.mandays_maxtemp_over_32c_1c) as agg_mandays_maxtemp_over_32c_1c,
                avg(a.man_distance_to_fire_brigade) as agg_man_distance_to_fire_brigade,
                avg(a.man_distance_to_hospital) as agg_man_distance_to_hospital,
                avg(a.total_road_length) as agg_total_road_length,
                avg(a.foursquare_places_count) as agg_foursquare_places_count,
                avg(a.foursquare_visits_count) as agg_foursquare_visits_count,
                avg(a.view_count_bf2402) as agg_view_count_bf2402,
                avg(a.raw_mhe_pop_scaled) as raw_mhe_pop_scaled,
                avg(a.raw_mhe_cap_scaled) as raw_mhe_cap_scaled,
                avg(a.raw_mhe_index) as raw_mhe_index,
                avg(a.relative_mhe_pop_scaled) as relative_mhe_pop_scaled,
                avg(a.relative_mhe_cap_scaled) as relative_mhe_cap_scaled,
                avg(a.relative_mhe_index) as relative_mhe_index,
                avg(a.mhe_index) as mhe_index,
                avg(a.life_expectancy_scale) as life_expectancy_scale,
                avg(a.infant_mortality_scale) as infant_mortality_scale,
                avg(a.maternal_mortality_scale) as maternal_mortality_scale,
                avg(a.prevalence_undernourished_scale) as prevalence_undernourished_scale,
                avg(a.vulnerable_health_status_index) as vulnerable_health_status_index,
                avg(a.pop_wout_improved_sanitation_scale) as pop_wout_improved_sanitation_scale,
                avg(a.pop_wout_improved_water_scale) as pop_wout_improved_water_scale,
                avg(a.clean_water_access_vulnerability_index) as clean_water_access_vulnerability_index,
                avg(a.adult_illiteracy_scale) as adult_illiteracy_scale,
                avg(a.gross_enrollment_scale) as gross_enrollment_scale,
                avg(a.years_of_schooling_scale) as years_of_schooling_scale,
                avg(a.pop_wout_internet_scale) as pop_wout_internet_scale,
                avg(a.info_access_vulnerability_index) as info_access_vulnerability_index,
                avg(a.export_minus_import_percent_scale) as export_minus_import_percent_scale,
                avg(a.average_inflation_scale) as average_inflation_scale,
                avg(a.economic_dependency_scale) as economic_dependency_scale,
                avg(a.economic_constraints_index) as economic_constraints_index,
                avg(a.female_govt_seats_scale) as female_govt_seats_scale,
                avg(a.female_male_secondary_enrollment_scale) as female_male_secondary_enrollment_scale,
                avg(a.female_male_labor_ratio_scale) as female_male_labor_ratio_scale,
                avg(a.gender_inequality_index) as gender_inequality_index,
                avg(a.max_political_discrimination_scale) as max_political_discrimination_scale,
                avg(a.max_economic_discrimination_scale) as max_economic_discrimination_scale,
                avg(a.ethnic_discrimination_index) as ethnic_discrimination_index,
                avg(a.marginalization_index) as marginalization_index,
                avg(a.population_change_scale) as population_change_scale,
                avg(a.urban_population_change_scale) as urban_population_change_scale,
                avg(a.population_pressures_index) as population_pressures_index,
                avg(a.freshwater_withdrawals_scale) as freshwater_withdrawals_scale,
                avg(a.forest_area_change_scale) as forest_area_change_scale,
                avg(a.ruminant_density_scale) as ruminant_density_scale,
                avg(a.environmental_stress_index) as environmental_stress_index,
                avg(a.recent_disaster_losses_scale) as recent_disaster_losses_scale,
                avg(a.recent_disaster_deaths_scale) as recent_disaster_deaths_scale,
                avg(a.recent_disaster_impacts_index) as recent_disaster_impacts_index,
                avg(a.recent_conflict_deaths_scale) as recent_conflict_deaths_scale,
                avg(a.displaced_populations_scale) as displaced_populations_scale,
                avg(a.conflict_impacts_index) as conflict_impacts_index,
                avg(a.vulnerability_index) as vulnerability_index,
                avg(a.voice_and_accountability_scale) as voice_and_accountability_scale,
                avg(a.rule_of_law_scale) as rule_of_law_scale,
                avg(a.political_stability_scale) as political_stability_scale,
                avg(a.govt_effectiveness_scale) as govt_effectiveness_scale,
                avg(a.control_of_corruption_scale) as control_of_corruption_scale,
                avg(a.governance_index) as governance_index,
                avg(a.gni_per_capita_scale) as gni_per_capita_scale,
                avg(a.reserves_per_capita_scale) as reserves_per_capita_scale,
                avg(a.economic_capacity_index) as economic_capacity_index,
                avg(a.fixed_phone_access_scale) as fixed_phone_access_scale,
                avg(a.mobile_phone_access_scale) as mobile_phone_access_scale,
                avg(a.internet_server_access_scale) as internet_server_access_scale,
                avg(a.communications_capacity_index) as communications_capacity_index,
                avg(a.port_rnwy_density_scale) as port_rnwy_density_scale,
                avg(a.road_rr_density_scale) as road_rr_density_scale,
                avg(a.transportation_index) as transportation_index,
                avg(a.hospital_bed_density_scale) as hospital_bed_density_scale,
                avg(a.nurses_midwives_scale) as nurses_midwives_scale,
                avg(a.physicians_scale) as physicians_scale,
                avg(a.health_care_capacity_index) as health_care_capacity_index,
                avg(a.infrastructure_capacity_index) as infrastructure_capacity_index,
                avg(a.biome_protection_scale) as biome_protection_scale,
                avg(a.marine_protected_area_scale) as marine_protected_area_scale,
                avg(a.environmental_capacity_index) as environmental_capacity_index,
                avg(a.coping_capacity_index) as coping_capacity_index,
                avg(a.resilience_index) as resilience_index,
                avg(a.mhr_index) as mhr_index
            from
                stat_h3 a
            where
                a.resolution between 1 and 6
            group by 1 ) a
    join stat_h3 b on a.h3_parent = b.h3
);

create or replace function estimate_bivariate_axis_quality (parameter1 text, parameter2 text)
    returns float
    language plpgsql
as
$$
declare
    quality float;
begin

    execute 'select (1.0::float-avg(' ||
            -- if we zoom in one step, will current zoom values be the same as next zoom values?
            'abs(('||parameter1||' / nullif('||parameter2||', 0)) - (agg_'||parameter1||' / nullif(agg_'||parameter2||', 0)))
            /
            nullif(('||parameter1||' / nullif('||parameter2||', 0)) + (agg_'||parameter1||' / nullif(agg_'||parameter2||', 0)), 0))' ||
            ')' ||
            -- does the denominator cover all of the cells where numerator is present?
            '* (' ||
            '(count(*) filter (where '||parameter1||' != 0 and '||parameter2||' != 0))::float ' ||
            '/ ' ||
            '(count(*) filter (where '||parameter1||' != 0))'||
            ' )'||
        'from stat_h3_quality' into quality;
    return quality;
end;
$$
    stable
    parallel safe;

drop table if exists bivariate_axis;
create table bivariate_axis as (
    select
        a.param_id as numerator,
        b.param_id as denominator,
        min,
        p25,
        p75,
        max,
        quality,
        '' as min_label,
        '' as p25_label,
        '' as p75_label,
        '' as max_label,
        '' as label
    from
        bivariate_indicators                                    as a,
        bivariate_indicators                                    as b,
        calculate_axis_stops(a.param_id, b.param_id)            as f,
        estimate_bivariate_axis_quality(a.param_id, b.param_id) as quality
    where
        b.is_base and a.param_id != b.param_id
);

analyse bivariate_axis;

update bivariate_axis
set
    label = 'Highway length (m/km²)'
where
      numerator = 'highway_length'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Population (ppl/km²)'
where
      numerator = 'population'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'OSM objects (n/km²)'
where
      numerator = 'count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Buildings (n/km²)'
where
      numerator = 'building_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Edits by active locals (h/km²)'
where
      numerator = 'local_hours'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Edits by all mappers (h/km²)'
where
      numerator = 'total_hours'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Map views, last 30 days (n/km²)'
where
      numerator = 'view_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'OpenStreetMap Contributors (n)'
where
      numerator = 'osm_users'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Total buildings count (n/km²)'
where
      numerator = 'total_building_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Wildfires (n/km²)'
where
      numerator = 'wildfires'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Forest Landcover Area (km²/km²)'
where
      numerator = 'forest'
  and denominator = 'area_km2';

update bivariate_axis set label = 'Last edit (date)' where numerator = 'avgmax_ts' and denominator = 'one';

update bivariate_axis
set
    min_label = to_char(to_timestamp(min), 'DD Mon YYYY'),
    p25_label = to_char(to_timestamp(p25), 'DD Mon YYYY'),
    p75_label = to_char(to_timestamp(p75), 'DD Mon YYYY'),
    max_label = to_char(to_timestamp(max), 'DD Mon YYYY')
where
      numerator in ('min_ts', 'max_ts', 'avgmax_ts')
  and denominator = 'one';

update bivariate_axis
set
    label = 'Number of days per year'
where
      numerator = 'days_maxtemp_over_32c_1c'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Number of nights per year'
where
      numerator = 'days_mintemp_above_25c_1c'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Man-distance to fire brigade'
where
      numerator = 'man_distance_to_fire_brigade'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Man-distance to hospitals'
where
      numerator = 'man_distance_to_hospital'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Total Roads Estimate (m/km²)'
where
      numerator = 'total_road_length'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Distance to fire station (km)'
where
      numerator = 'man_distance_to_fire_brigade'
  and denominator = 'population';

update bivariate_axis
set
    label = 'OSM roads density (m/km²)'
where
      numerator = 'highway_length'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'OSM roads density (m/km²)'
where
      numerator = 'highway_length'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Meta and OSM roads density (m/km2)'
where
      numerator = 'total_road_length'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Foursquare Japan places count'
where
      numerator = 'foursquare_places_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Foursquare Japan visits count'
where
      numerator = 'foursquare_visits_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Map views 30 days before 24.02.2022'
where
      numerator = 'view_count_bf2402'
  and denominator = 'one';

update bivariate_axis
set
    label = 'OSM Map Views, Jan 25-Feb 24 2022, n/km²)'
where
      numerator = 'view_count_bf2402'
  and denominator = 'area_km2';

-- columns for advanced analytics
alter table bivariate_axis
    add column sum_value double precision,
    add column sum_quality double precision,
    add column min_value double precision,
    add column min_quality double precision,
    add column max_value double precision,
    add column max_quality double precision,
    add column stddev_value double precision,
    add column stddev_quality double precision,
    add column median_value double precision,
    add column median_quality double precision,
    add column mean_value double precision,
    add column mean_quality double precision;