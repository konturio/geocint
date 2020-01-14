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
