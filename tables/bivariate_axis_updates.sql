update bivariate_axis
set
    label = 'Highway length (km/km²)'
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
    label = 'Number of days with any disaster occurs, last year (n/km²)',
    min = 0
where
      numerator = 'hazardous_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days with any disaster occurs, last year (n)',
    min = 0
where
      numerator = 'hazardous_days_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Number of days under earthquake impact, last year (n/km²)',
    min = 0
where
      numerator = 'earthquake_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under earthquake impact, last year (n)',
    min = 0
where
      numerator = 'earthquake_days_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Number of days under drought impact, last year (n/km²)',
    min = 0
where
      numerator = 'drought_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under drought impact, last year (n)',
    min = 0
where
      numerator = 'drought_days_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Number of days under cyclone impact, last year (n/km²)',
    min = 0
where
      numerator = 'cyclone_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under cyclone impact, last year (n)',
    min = 0
where
      numerator = 'cyclone_days_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Number of days under wildfire impact, last year (n/km²)',
    min = 0
where
      numerator = 'wildfire_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under wildfire impact, last year (n)',
    min = 0
where
      numerator = 'wildfire_days_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Number of days under volcano impact, last year (n/km²)',
    min = 0
where
      numerator = 'volcano_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under volcano impact, last year (n)',
    min = 0
where
      numerator = 'volcano_days_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Number of days under flood impact, last year (n/km²)',
    min = 0
where
      numerator = 'flood_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under flood impact, last year (n)',
    min = 0
where
      numerator = 'flood_days_count'
  and denominator = 'one';

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
    label = 'Distance to fire station (km)',
    p25 = 3.0,
    p75 = 10.0
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
    label = 'OSM Map Views, Jan 25-Feb 24 2022 (n/km²)'
where
      numerator = 'view_count_bf2402'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Medium voltage powerlines distribution estimation'
where
      numerator = 'powerlines'
  and denominator = 'one';

update bivariate_axis
set
    label = 'OSM roads completeness',
    p75 = 0.9,
    max = 1.01
where
      numerator = 'highway_length'
  and denominator = 'total_road_length';

update bivariate_axis
set
    label = 'VIIRS Nighttime lights intensity'
where
      numerator = 'night_lights_intensity'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Number of OSM eateries',
    min = 0
where
      numerator = 'eatery_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Number of OSM food shops',
    min = 0
where
      numerator = 'food_shops_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Man-distance to bomb shelters'
where
      numerator = 'man_distance_to_bomb_shelters'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Man-distance to electric car charging stations'
where
      numerator = 'man_distance_to_charging_stations'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Distance to electric car charging stations (km)',
    p25 = 3.0,
    p75 = 30.0
where
      numerator = 'man_distance_to_charging_stations'
 and denominator = 'population';

update bivariate_axis
set
    label = 'Waste basket coverage (coverage / populated area)',
    p25 = 0.2,
    p75 = 0.5,
    max = 1.0
where numerator = 'waste_basket_coverage_area_km2' and denominator = 'populated_area_km2';

update bivariate_axis
set
    label = 'Distance to bomb shelters (km)',
    p25 = 3.0,
    p75 = 10.0
where
      numerator = 'man_distance_to_bomb_shelters'
  and denominator = 'population';