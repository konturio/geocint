drop table if exists covid_cases_us_counties_names;
create table covid_cases_us_counties_names as (
    select a.issue,
           a.value,
           b.state,
           b.county,
           b.hasc_code,
           b.fips_code
    from covid_cases_us_counties a
             join counties_fips_hasc b
                  on a.geo_value = b.fips_code
);


drop table if exists covid_cases_us_counties_geom;
create table covid_cases_us_counties_geom as (
    select a.*, b.wkb_geometry as geom
    from covid_cases_us_counties_names a
             join gadm_us_counties_boundary b
                  on b.hasc_2 = a.hasc_code
);

create index on covid_cases_us_counties_geom using gist(geom);
