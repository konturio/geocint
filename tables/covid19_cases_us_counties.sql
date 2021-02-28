drop table if exists covid19_cases_us_counties;
create table covid19_cases_us_counties as (
    select b.geom,
           b.state,
           b.county,
           b.fips_code,
           array_agg(issue)      as issue_time,
           avg(value)            as cases_value
    from covid19_cases_us_counties_csv a
             join us_counties_boundary b
                  on a.geo_value = b.fips_code
    group by 1, 2, 3, 4
);
create index on covid19_cases_us_counties using gist (geom);
