drop table if exists covid19_cases_us_counties;
create table covid19_cases_us_counties as (
    select a.issue,
           a.value,
           b.state,
           b.county,
           b.hasc_code,
           b.fips_code,
           b.geom
    from covid_cases_us_counties a
             join us_counties_boundary b
                  on a.geo_value = b.fips_code
);

create index on covid19_cases_us_counties using gist (geom);

