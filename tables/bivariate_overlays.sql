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
       'Kontur OpenStreetMap Mapping Activity',
       'local_hours',
       'area_km2',
       'total_hours',
       'area_km2',
       false,
       'Greener - stronger local community, darker - more active mapping. This map shows how active mapping in the area in last two years is. All mapping hours are shown against mapping hours we can surely attribute to an active local user. Mapper is considered active if they contributed more than 30 mapping hours during last two years. Position of active mapper is estimated by region of their highest activity. A mapping hour is a hour in which an user uploaded at least one tagged object. Last updated  ' ||
       json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
       '[{"id": "A1","color": "#ada9c8"},{"id": "A2","color": "#7a71b2"},{"id": "A3","color": "#5d5398"},{"id": "B1","color": "#9db7b5"},{"id": "B2","color": "#768e9f"},{"id": "B3","color": "#587681"},{"id": "C1","color": "#89c89e"},{"id": "C2","color": "#71b287"},{"id": "C3","color": "rgb(83,152,106)"}]'
from osm_meta;

insert into bivariate_overlays (ord, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 5,
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
