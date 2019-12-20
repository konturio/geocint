drop table if exists bivariate_overlays;

create table bivariate_overlays
(
    name          text,
    x_numerator   text,
    x_denominator text,
    y_numerator   text,
    y_denominator text,
    active        boolean
);

insert into bivariate_overlays (name, x_numerator, x_denominator, y_numerator, y_denominator, active)
values ('OSM objects count and population map', 'count', 'area_km2', 'population', 'area_km2', true);
insert into bivariate_overlays (name, x_numerator, x_denominator, y_numerator, y_denominator, active)
values ('Building count and population map', 'building_count', 'area_km2', 'population', 'area_km2', false);
insert into bivariate_overlays (name, x_numerator, x_denominator, y_numerator, y_denominator, active)
values ('Highway length and population map', 'highway_length', 'area_km2', 'population', 'area_km2', false);
