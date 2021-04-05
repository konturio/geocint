drop table if exists covid19_cases_us_counties;
create table covid19_cases_us_counties as (
    select b.geom,
           b.state,
           b.county,
           b.fips_code,
           avg(value)            as covid19_cases
    from covid19_us_counties_in a
             join us_counties_boundary b
                  on a.geo_value = b.fips_code
    where a.value > 0
    group by 1, 2, 3, 4
);
create index on covid19_cases_us_counties using gist (geom);
alter table covid19_cases_us_counties set (parallel_workers = 32);
