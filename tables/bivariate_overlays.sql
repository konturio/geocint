drop table if exists bivariate_overlays;

create table bivariate_overlays
(
    order         float,
    name          text,
    description   text,
    x_numerator   text,
    x_denominator text,
    y_numerator   text,
    y_denominator text,
    active        boolean,
    colors        jsonb
);

insert into bivariate_overlays (order, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 1, 
       'Kontur OpenStreetMap Quantity',
       'count',
       'area_km2',
       'population',
       'area_km2',
       true,
       'This map shows relative distribution of OpenStreetMap objects and Population. Last updated ' ||
       json_extract_path_text(meta::json, 'header', 'option', 'timestamp'),
       '[{id:"A1",color:"rgb(232,232,157)"},{id:"A2",color:"rgb(228,127,129)"},{id:"A3",color:"rgb(228,26,28)"},{id:"B1",color:"rgb(173,228,191)"},{id:"B2",color:"rgb(173,173,108)"},{"id:"B3",color:"rgb(140,98,98)"},{id:"C1",color:"rgb(90,200,127)"},{id:"C2",color:"rgb(77,175,74)"},{id:"C3",color:"rgb(83,152,106)"}]'
from osm_meta;

insert into bivariate_overlays (order, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 2,
       'Kontur OpenStreetMap Building Quantity',
       'building_count',
       'area_km2',
       'population',
       'area_km2',
       false,
       'This map shows whether all populated houses are mapped in OpenStreetMap. Last updated  ' ||
       json_extract_path_text(meta::json, 'header', 'option', 'timestamp'),
       '[{id:"A1",color:"rgb(232,232,157)"},{id:"A2",color:"rgb(228,127,129)"},{id:"A3",color:"rgb(228,26,28)"},{id:"B1",color:"rgb(173,228,191)"},{id:"B2",color:"rgb(173,173,108)"},{"id:"B3",color:"rgb(140,98,98)"},{id:"C1",color:"rgb(90,200,127)"},{id:"C2",color:"rgb(77,175,74)"},{id:"C3",color:"rgb(83,152,106)"}]'
from osm_meta;

insert into bivariate_overlays (order, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 3,
       'Kontur OpenStreetMap Road Length',
       'highway_length',
       'area_km2',
       'population',
       'area_km2',
       false,
       'This map shows whether populated places have roads to visit them or escape. Last updated  ' ||
       json_extract_path_text(meta::json, 'header', 'option', 'timestamp')
       '[{id:"A1",color:"rgb(232,232,157)"},{id:"A2",color:"rgb(228,127,129)"},{id:"A3",color:"rgb(228,26,28)"},{id:"B1",color:"rgb(173,228,191)"},{id:"B2",color:"rgb(173,173,108)"},{"id:"B3",color:"rgb(140,98,98)"},{id:"C1",color:"rgb(90,200,127)"},{id:"C2",color:"rgb(77,175,74)"},{id:"C3",color:"rgb(83,152,106)"}]'
from osm_meta;

insert into bivariate_overlays (order, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 5,
       'Kontur OpenStreetMap Mapping Activity',
       'local_hours',
       'area_km2',
       'total_hours',
       'area_km2',
       false,
       'This map shows how active mapping in the area in last two years is. All mapping hours are shown against mapping hours we can surely attribute to an active local user. Mapper is considered active if they contributed more than 30 mapping hours during last two years. Position of active mapper is estimated by region of their highest activity. A mapping hour is a hour in which an user uploaded at least one tagged object. Last updated  ' ||
       json_extract_path_text(meta::json, 'header', 'option', 'timestamp'),
       '[{id:"A1",color:"rgb(232,232,157)"},{id:"A2",color:"rgb(228,127,129)"},{id:"A3",color:"rgb(228,26,28)"},{id:"B1",color:"rgb(173,228,191)"},{id:"B2",color:"rgb(173,173,108)"},{"id:"B3",color:"rgb(140,98,98)"},{id:"C1",color:"rgb(90,200,127)"},{id:"C2",color:"rgb(77,175,74)"},{id:"C3",color:"rgb(83,152,106)"}]'
from osm_meta;

insert into bivariate_overlays (order, name, x_numerator, x_denominator, y_numerator, y_denominator, active, description, colors)
select 4,
       'Kontur OpenStreetMap Data Age',
       'p90_ts',
       'one',
       'osm_users',
       'one',
       false,
       'This map shows how old is OpenSteetMap in particular region and how big is group of users that created it. Explore to find import, mapping parties and large local communities. Last updated ' ||
       json_extract_path_text(meta::json, 'header', 'option', 'timestamp'),
       '[{id:"A1",color:"rgb(232,232,157)"},{id:"A2",color:"rgb(228,127,129)"},{id:"A3",color:"rgb(228,26,28)"},{id:"B1",color:"rgb(173,228,191)"},{id:"B2",color:"rgb(173,173,108)"},{"id:"B3",color:"rgb(140,98,98)"},{id:"C1",color:"rgb(90,200,127)"},{id:"C2",color:"rgb(77,175,74)"},{id:"C3",color:"rgb(83,152,106)"}]'
from osm_meta;
