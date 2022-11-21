drop table if exists bivariate_unit_localization;
create table bivariate_unit_localization
(
    unit_id   text not null primary key,
    language text,
    short_name text,
    long_name text
);

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('m', 'en', 'm', 'meters');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('km', 'en', 'km', 'kilometers');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('km2', 'en', 'km²', 'square kilometers');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('h', 'en', 'h', 'hours');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('days', 'en', 'days', 'days');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('deg', 'en', '°', 'degrees');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('nW_cm2_sr', 'en', 'nW/cm²/sr', 'watts per square centimeter per steradian');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('unixtime', 'en', 'date', 'date');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('celc_deg', 'en', '°C', 'degrees Celsius');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('W_m2', 'en', 'W/m²', 'watt per square metre');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('USD', 'en', 'USD', 'United States dollar');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('index', 'en', 'index', 'index');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('other', 'en', NULL, NULL);

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('n', 'en', 'n', 'number');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('ppl', 'en', 'ppl', 'people');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('perc', 'en', '%', 'percentage');

insert into bivariate_unit_localization (unit_id, language, short_name, long_name)
values ('fract', 'en', 'fraction', 'fraction');