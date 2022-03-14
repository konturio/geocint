drop table if exists bivariate_overlays;

create table bivariate_overlays
(
    ord           float,
    name          text,
    description   text,
    x_numerator   text,
    x_denominator text,
    y_numerator   text,
    y_denominator text,
    active        boolean,
    colors        jsonb
);

insert into bivariate_overlays (ord, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 1,
       'Kontur OpenStreetMap Quantity',
       'count',
       'area_km2',
       'population',
       'area_km2',
       true,
       'This map shows relative distribution of OpenStreetMap objects and Population. Last updated ' ||
       json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
       '[{"id":"A1","color":"rgb(232,232,157)"},{"id":"A2","color":"rgb(228,127,129)"},{"id":"A3","color":"rgb(228,26,28)"},{"id":"B1","color":"rgb(173,228,191)"},{"id":"B2","color":"rgb(173,173,108)"},{"id":"B3","color":"rgb(140,98,98)"},{"id":"C1","color":"rgb(90,200,127)"},{"id":"C2","color":"rgb(77,175,74)"},{"id":"C3","color":"rgb(83,152,106)"}]'
from osm_meta;

insert into bivariate_overlays (ord, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 2,
       'Kontur OpenStreetMap Building Quantity',
       'building_count',
       'area_km2',
       'population',
       'area_km2',
       false,
       'This map shows whether all populated houses are mapped in OpenStreetMap. Last updated  ' ||
       json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
       '[{"id":"A1","color":"rgb(232,232,157)"},{"id":"A2","color":"rgb(228,127,129)"},{"id":"A3","color":"rgb(228,26,28)"},{"id":"B1","color":"rgb(173,228,191)"},{"id":"B2","color":"rgb(173,173,108)"},{"id":"B3","color":"rgb(140,98,98)"},{"id":"C1","color":"rgb(90,200,127)"},{"id":"C2","color":"rgb(77,175,74)"},{"id":"C3","color":"rgb(83,152,106)"}]'
from osm_meta;

insert into bivariate_overlays (ord, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 3,
       'Kontur OpenStreetMap Road Length',
       'highway_length',
       'area_km2',
       'population',
       'area_km2',
       false,
       'This map shows whether populated places have roads to visit them or escape in time of disaster. Last updated  ' ||
       json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
       '[{"id":"A1","color":"rgb(232,232,157)"},{"id":"A2","color":"rgb(228,127,129)"},{"id":"A3","color":"rgb(228,26,28)"},{"id":"B1","color":"rgb(173,228,191)"},{"id":"B2","color":"rgb(173,173,108)"},{"id":"B3","color":"rgb(140,98,98)"},{"id":"C1","color":"rgb(90,200,127)"},{"id":"C2","color":"rgb(77,175,74)"},{"id":"C3","color":"rgb(83,152,106)"}]'
from osm_meta;

insert into bivariate_overlays (ord, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 4,
       'Kontur OpenStreetMap Road Length Beta',
       'highway_length',
       'area_km2',
       'total_road_length',
       'area_km2',
       false,
       'This map shows possible gaps in OpenStreetMap roads data. It shows the ratio of road density in OpenStreetMap to road density according to Meta and OpenStreetMap data. Last updated  ' ||
       json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
       '[{"id":"A1","color":"rgb(232,232,157)"},{"id":"A2","color":"rgb(228,127,129)"},{"id":"A3","color":"rgb(228,26,28)"},{"id":"B1","color":"rgb(173,228,191)"},{"id":"B2","color":"rgb(173,173,108)"},{"id":"B3","color":"rgb(140,98,98)"},{"id":"C1","color":"rgb(90,200,127)"},{"id":"C2","color":"rgb(77,175,74)"},{"id":"C3","color":"rgb(83,152,106)"}]'
from osm_meta;


insert into bivariate_overlays (ord, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 5,
       'Kontur OpenStreetMap Mapping Activity',
       'local_hours',
       'area_km2',
       'total_hours',
       'area_km2',
       false,
       'Greener - stronger local community, darker - more active mapping. This map shows how active mapping in the area in last two years is. All mapping hours are shown against mapping hours we can surely attribute to an active local user. Mapper is considered active if they contributed more than 30 mapping hours during last two years. Position of active mapper is estimated by region of their highest activity. A mapping hour is a hour in which an user uploaded at least one tagged object. Last updated  ' ||
       json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
       '[{"id":"A1","color":"rgb(173,169,200)"},{"id":"A2","color":"rgb(122,113,178)"},{"id":"A3","color":"rgb(93,83,152)"},{"id":"B1","color":"rgb(157,183,181)"},{"id":"B2","color":"rgb(118,142,159)"},{"id":"B3","color":"rgb(88,118,129)"},{"id":"C1","color":"rgb(137,200,158)"},{"id":"C2","color":"rgb(113,178,135)"},{"id":"C3","color":"rgb(83,152,106)"}]'
from osm_meta;

insert into bivariate_overlays (ord, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 6,
       'Kontur OpenStreetMap Antiquity',
       'avgmax_ts',
       'one',
       'view_count',
       'area_km2',
       false,
       'This map shows how old is OpenStreetMap and how many times users view in particular region of OpenStreetMap for the last 30 days. Explore to find the least edited, but the most popular areas at the same time. Last updated ' ||
        max(tile_date),
       '[{"id":"A1","color":"rgb(232,232,157)"},{"id":"A2","color":"rgb(228,127,129)"},{"id":"A3","color":"rgb(228,26,28)"},{"id":"B1","color":"rgb(173,228,191)"},{"id":"B2","color":"rgb(173,173,108)"},{"id":"B3","color":"rgb(140,98,98)"},{"id":"C1","color":"rgb(90,200,127)"},{"id":"C2","color":"rgb(77,175,74)"},{"id":"C3","color":"rgb(83,152,106)"}]'
from tile_logs;

insert into bivariate_overlays (ord, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 7,
       'Kontur Nighttime Heatwave Risk',
       'days_mintemp_above_25c_1c',
       'one',
       'population',
       'area_km2',
       false,
       'This map shows heat-stress risk areas, where nighttime temperatures stay above 25°C. Due to the increase of greenhouse gases the nighttime temperatures are growing at a rate of 0.07 degrees per decade, compared to 0.05 degrees for daytime maximums globally (for the period from 1960 to 2009).
       The number of people exposed to nighttime heatwaves in particular regions is provided by Kontur. The current warming scenario of the average number of nights over 25°C during the year is based on data and other content made available by Probable Futures, a Project of SouthCoast Community Foundation, and certain of that data may have been provided to Probable Futures by Woodwell Climate Research Center, Inc. or The Coordinated Regional climate Downscaling Experiment (CORDEX).',
       '[{"id":"A1","color":"rgb(103,176,100)"},{"id":"A2","color":"rgb(103,176,100)"},{"id":"A3","color":"rgb(103,176,100)"},{"id":"B1","color":"rgb(232,232,157)"},{"id":"B2","color":"rgb(228,185,129)"},{"id":"B3","color":"rgb(228,127,129)"},{"id":"C1","color":"rgb(232,232,157)"},{"id":"C2","color":"rgb(229,154,55)"},{"id":"C3","color":"rgb(228,26,28)"}]';

insert into bivariate_overlays (ord, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 8,
       'Kontur Fire Service Scarcity Risk',
       'man_distance_to_fire_brigade',
       'population',
       'population',
       'area_km2',
       false,
       'This map shows areas at higher risk in case of a fire due to population density and fire station distance ratio' ||
       json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
       '[{"id":"A1","color":"rgb(103,176,100)"},{"id":"A2","color":"rgb(103,176,100)"},{"id":"A3","color":"rgb(103,176,100)"},{"id":"B1","color":"rgb(232,232,157)"},{"id":"B2","color":"rgb(228,185,129)"},{"id":"B3","color":"rgb(228,127,129)"},{"id":"C1","color":"rgb(232,232,157)"},{"id":"C2","color":"rgb(229,154,55)"},{"id":"C3","color":"rgb(228,26,28)"}]'
from osm_meta;
