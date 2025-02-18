drop table if exists bivariate_axis_overrides;

create table bivariate_axis_overrides(
    numerator       text,
    denominator     text,
    min double precision,
    p25 double precision,
    p75 double precision,
    max double precision,
    label text
);

alter table bivariate_axis_overrides
add constraint ba_overrides_key unique (numerator, denominator);

insert into bivariate_axis_overrides
    (numerator, denominator, label)
values
    ('population', 'area_km2', 'Population'),
    ('count', 'area_km2', 'OSM objects'),
    ('building_count', 'area_km2', 'Buildings'),
    ('building_count', 'total_building_count', 'OSM Building completeness'),
    ('local_hours', 'area_km2', 'Edits by active locals'),
    ('total_hours', 'area_km2', 'Edits by all mappers'),
    ('view_count', 'area_km2', 'Map views, last 30 days'),
    ('osm_users', 'one', 'OpenStreetMap Contributors'),
    ('total_building_count', 'area_km2', 'Total buildings count'),
    ('wildfires', 'area_km2', 'Wildfires'),
    ('hazardous_days_count', 'area_km2', 'Number of days with any disaster occurs, last year'),
    ('hazardous_days_count', 'one', 'Number of days with any disaster occurs, last year'),
    ('earthquake_days_count', 'area_km2', 'Number of days under earthquake impact, last year'),
    ('earthquake_days_count', 'one', 'Number of days under earthquake impact, last year'),
    ('drought_days_count', 'area_km2', 'Number of days under drought impact, last year'),
    ('drought_days_count', 'one', 'Number of days under drought impact, last year'),
    ('cyclone_days_count', 'area_km2', 'Number of days under cyclone impact, last year'),
    ('cyclone_days_count', 'one', 'Number of days under cyclone impact, last year'),
    ('wildfire_days_count', 'area_km2', 'Number of days under wildfire impact, last year'),
    ('wildfire_days_count', 'one', 'Number of days under wildfire impact, last year'),
    ('volcano_days_count', 'area_km2', 'Number of days under volcano impact, last year'),
    ('volcano_days_count', 'one', 'Number of days under volcano impact, last year'),
    ('flood_days_count', 'area_km2', 'Number of days under flood impact, last year'),
    ('flood_days_count', 'one', 'Number of days under flood impact, last year'),
    ('forest', 'area_km2', 'Forest Landcover Area'),
    ('days_maxtemp_over_32c_1c', 'one', 'Number of days per year with temperature above 32°C wet-bulb'),
    ('days_mintemp_above_25c_1c', 'one', 'Number of nights per year with temperature above 25°C'),
    ('man_distance_to_fire_brigade', 'one', 'Man-distance to fire brigade'),
    ('man_distance_to_hospital', 'one', 'Man-distance to hospitals'),
    ('man_distance_to_fire_brigade', 'population', 'Distance to fire station'),
    ('man_distance_to_hospital', 'population', 'Distance to hospitals'),
    ('highway_length', 'area_km2', 'OSM roads density'),
    ('total_road_length', 'area_km2', 'Total roads density estimate'),
    --('foursquare_places_count', 'one', 'Foursquare Japan places count'),
    --('foursquare_visits_count', 'one', 'Foursquare Japan visits count'),
    ('view_count_bf2402', 'one', 'Map views 30 days before 24.02.2022'),
    ('view_count_bf2402', 'area_km2', 'OSM Map Views, Jan 25-Feb 24 2022'),
    ('powerlines', 'one', 'Medium voltage powerlines distribution estimation'),
    ('highway_length', 'total_road_length', 'OSM roads completeness'),
    ('night_lights_intensity', 'one', 'VIIRS Nighttime lights intensity'),
    ('eatery_count', 'one', 'Number of OSM eateries'),
    ('food_shops_count', 'one', 'Number of OSM food shops'),
    ('man_distance_to_bomb_shelters', 'one', 'Man-distance to bomb shelters'),
    ('man_distance_to_food_shops_eatery', 'one', 'Man-distance to food shops and eatery'),
    ('man_distance_to_charging_stations', 'one', 'Man-distance to electric car charging stations'),
    ('man_distance_to_charging_stations', 'population', 'Distance to electric car charging stations'),
    ('man_distance_to_food_shops_eatery', 'population', 'Distance to food shops and eatery'),
    ('waste_basket_coverage_area_km2' , 'populated_area_km2', 'Waste basket coverage (coverage / populated area)'),
    ('man_distance_to_bomb_shelters', 'population', 'Distance to shelters'),
    ('solar_power_plants', 'area_km2', 'Solar power plants');


insert into bivariate_axis_overrides
    (numerator, denominator, p25)
values
    ('waste_basket_coverage_area_km2' , 'populated_area_km2', 0.2),
    ('man_distance_to_bomb_shelters', 'population', 3.0),
    ('man_distance_to_charging_stations', 'population', 3.0),
    ('man_distance_to_fire_brigade', 'population', 3.0),
    ('man_distance_to_food_shops_eatery', 'population', 3.0)
on conflict (numerator, denominator) do update
set p25 = excluded.p25;

insert into bivariate_axis_overrides
    (numerator, denominator, p75)
values
    ('waste_basket_coverage_area_km2' , 'populated_area_km2', 0.5),
    ('man_distance_to_bomb_shelters', 'population', 10.0),
    ('man_distance_to_charging_stations', 'population', 30.0),
    ('man_distance_to_fire_brigade', 'population', 10.0),
    ('man_distance_to_food_shops_eatery', 'population', 15.0),
    ('building_count', 'total_building_count', 0.9),
    ('highway_length', 'total_road_length', 0.9)
on conflict (numerator, denominator) do update
set p75 = excluded.p75;

insert into bivariate_axis_overrides
    (numerator, denominator, max)
values
    ('waste_basket_coverage_area_km2' , 'populated_area_km2', 1.0),
    ('highway_length', 'total_road_length', 1.01)
on conflict (numerator, denominator) do update
set max = excluded.max;

insert into bivariate_axis_overrides
    (numerator, denominator, min)
values
    ('eatery_count', 'one', 0),
    ('food_shops_count', 'one', 0),
    ('hazardous_days_count', 'area_km2', 0),
    ('hazardous_days_count', 'one', 0),
    ('earthquake_days_count', 'area_km2', 0),
    ('earthquake_days_count', 'one', 0),
    ('drought_days_count', 'area_km2', 0),
    ('drought_days_count', 'one', 0),
    ('cyclone_days_count', 'area_km2', 0),
    ('cyclone_days_count', 'one', 0),
    ('wildfire_days_count', 'area_km2', 0),
    ('wildfire_days_count', 'one', 0),
    ('volcano_days_count', 'area_km2', 0),
    ('volcano_days_count', 'one', 0),
    ('flood_days_count', 'area_km2', 0),
    ('flood_days_count', 'one', 0)
on conflict (numerator, denominator) do update
set min = excluded.min;
