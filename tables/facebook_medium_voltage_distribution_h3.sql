drop table if exists facebook_medium_voltage_distribution_h3_mid;

create table facebook_medium_voltage_distribution_h3_mid
(
    h3         h3index,
    resolution int,
    powerlines int not null default 1
);

-- notice that source data has resolution ~7.5 so we have gaps on 8 level
-- on conflict do nothing without distict is 20% slower.
insert into facebook_medium_voltage_distribution_h3_mid (h3, resolution, powerlines) (
    select h3_lat_lng_to_cell(ST_Point(lon, lat, 4326)::point, 8),
                    8::int,
                    value
    from facebook_medium_voltage_distribution_in
);

-- apply distinct on h3 to avoid duplicated hexagons in stat_h3
drop table if exists facebook_medium_voltage_distribution_h3;
create table facebook_medium_voltage_distribution_h3 as
    select distinct on (h3) h3,
                            resolution,
                            powerlines
    from facebook_medium_voltage_distribution_h3_mid
    order by 1;

drop table if exists facebook_medium_voltage_distribution_h3_mid;