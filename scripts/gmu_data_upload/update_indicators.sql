create table if not exists bivariate_indicators
(
    param_id   text,
    param_label text,
    copyrights json,
    direction json,
    is_base boolean not null default false,
    description text,
    coverage text,
    update_frequency text,
    is_public boolean,
    application json,
    unit_id text,
    emoji text,
    downscale text
);

insert into bivariate_indicators (
    param_id, param_label, copyrights,
    direction, description, coverage,
    update_frequency, unit_id, is_public, emoji, downscale
) values

-- GMU Air Temperature
('gmu_air_temperature', 'GMU Air Temperature Dataset', 
 '["2025 George Mason University", "National Interagency Fire Center"]'::json, 
 '[["good"], ["bad"]]'::jsonb, 
 'Temperature of the air surrounding the weather station instrumentation.', 
 'United States', 'every_20min', 'fahrenheit', TRUE, '🌡️', 'equal'),

-- GMU Rain Accumulation
('gmu_rain_accumulation', 'GMU Rain Accumulation Dataset', 
 '["2025 George Mason University", "National Interagency Fire Center"]'::json,
 '[["bad"], ["good"]]'::jsonb,
 'The cumulative total of rainfall for the rain year.',
 'United States', 'every_20min', 'inches', TRUE, '🌧️', 'equal'),

-- GMU Relative Humidity
('gmu_relative_humidity', 'GMU Relative Humidity Dataset', 
 '["2025 George Mason University", "National Interagency Fire Center"]'::json,
 '[["bad"], ["good"]]'::jsonb,
 'Relative humidity is the % ratio of the actual amount of water vapor in the air to the amount of water vapor required for saturation at existing temperature.',
 'United States', 'every_20min', 'percentage', TRUE, '💧', 'equal'),

-- GMU Solar Radiation
('gmu_solar_radiation', 'GMU Solar Radiation Dataset', 
 '["2025 George Mason University", "National Interagency Fire Center"]'::json,
 '[["bad"], ["good"]]'::jsonb,
 'Solar radiation is the amount of sunlight energy delivered to local fuels.',
 'United States', 'every_20min', 'watts per square meter', TRUE, '☀️', 'equal'),

-- GMU Wind Direction
('gmu_wind_direction', 'GMU Wind Direction Dataset', 
 '["2025 George Mason University", "National Interagency Fire Center"]'::json,
 '[["unimportant"], ["important"]]'::jsonb,
 'The direction from which the air is moving, in degrees from true north.',
 'United States', 'every_20min', 'degrees', TRUE, '🧭', 'equal'),

-- GMU Peak Wind Direction
('gmu_peak_wind_direction', 'GMU Peak Wind Direction Dataset', 
 '["2025 George Mason University", "National Interagency Fire Center"]'::json,
 '[["unimportant"], ["important"]]'::jsonb,
 'The direction from which the air is moving, at peak wind speed, in degrees from true north.',
 'United States', 'every_20min', 'degrees', TRUE, '🧭', 'equal'),

-- GMU Wind Speed
('gmu_wind_speed', 'GMU Wind Speed Dataset', 
 '["2025 George Mason University", "National Interagency Fire Center"]'::json,
 '[["good"], ["bad"]]'::jsonb,
 'Wind speed is the rate at which air passes a given point.',
 'United States', 'every_20min', 'mph', TRUE, '💨', 'equal'),

-- GMU Peak Wind Speed
('gmu_peak_wind_speed', 'GMU Peak Wind Speed Dataset', 
 '["2025 George Mason University", "National Interagency Fire Center"]'::json,
 '[["good"], ["bad"]]'::jsonb,
 'Maximum speed for previous 60 minutes from no less than 720 samples.',
 'United States', 'every_20min', 'mph', TRUE, '💨', 'equal');