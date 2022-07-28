drop table if exists facebook_medium_voltage_distribution_h3;

create table facebook_medium_voltage_distribution_h3
(
    h3         h3index,
    resolution int,
    powerlines int not null default 1
);

-- notice that source data has resolution ~7.5 so we have gaps on 8 level
-- on conflict do nothing without distict is 20% slower.
insert into facebook_medium_voltage_distribution_h3 (h3, resolution, powerlines) (
    select h3_geo_to_h3(ST_Point(lon, lat, 4326), 8),
                    8::int,
                    value
    from facebook_medium_voltage_distribution_in
);
