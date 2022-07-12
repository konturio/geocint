drop table if exists facebook_medium_voltage_distribution_h3;

create table facebook_medium_voltage_distribution_h3(
    h3 h3index primary key,
    resolution smallint generated always as (h3_get_resolution(h3)) stored,
    powerlines smallint not null default 1
);

-- notice that source data has resolution ~7.5 so we have gaps on 8 level
-- on conflict do nothing without distict is 20% slower.
insert into facebook_medium_voltage_distribution_h3 (h3) (
    select distinct
        h3_geo_to_h3(ST_Point(lon, lat, 4326), resolution)
    from
        facebook_medium_voltage_distribution_in, generate_series(0, 8) as resolution
);

-- h3 as pk is quite useless in folowing operations but it might be
-- a good point to start increasing stat_h3 performance.
-- stat_h3 is the only place where our table is used at the moment.
