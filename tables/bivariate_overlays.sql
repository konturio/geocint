drop table if exists bivariate_overlays;

create table bivariate_overlays
(
    name          text,
    description   text,
    x_numerator   text,
    x_denominator text,
    y_numerator   text,
    y_denominator text,
    active        boolean
);

insert into bivariate_overlays (name, x_numerator, x_denominator, y_numerator, y_denominator, active, description)
select 'OSM objects count and population map',
       'count',
       'area_km2',
       'population',
       'area_km2',
       true,
       'This map shows relative distribution of OSM objects count and Population. Last updated ' ||
       json_extract_path_text(meta::json, 'header', 'option', 'timestamp')
from osm_meta;

insert into bivariate_overlays (name, x_numerator, x_denominator, y_numerator, y_denominator, active, description)
select 'Building count and population map',
       'building_count',
       'area_km2',
       'population',
       'area_km2',
       false,
       'This map shows relative distribution of Building count and Population. Last updated  ' ||
       json_extract_path_text(meta::json, 'header', 'option', 'timestamp')
from osm_meta;

insert into bivariate_overlays (name, x_numerator, x_denominator, y_numerator, y_denominator, active, description)
select 'Highway length and population map',
       'highway_length',
       'area_km2',
       'population',
       'area_km2',
       false,
       'This map shows relative distribution of Highway length and Population. Last updated  ' ||
       json_extract_path_text(meta::json, 'header', 'option', 'timestamp')
from osm_meta;

insert into bivariate_overlays (name, x_numerator, x_denominator, y_numerator, y_denominator, active, description)
select 'OpenStreetMap Mapping Activity',
       'local_hours',
       'area_km2',
       'total_hours',
       'area_km2',
       false,
       'This layer shows how active mapping in the area in last two years is. All mapping hours are mapped and shown against mapping hours we can surely attribute to an active local user. Mapper is considered active if they contributed  more than 30 mapping hours during last two years. Position of active mapper is estimated by region of their highest activity. A mapping hour is a hour in which an user uploaded at least one tagged object. Last updated  ' ||
       json_extract_path_text(meta::json, 'header', 'option', 'timestamp')
from osm_meta;
