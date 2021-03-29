drop table if exists covid19_vaccine_accept_us_counties;
create table covid19_vaccine_accept_us_counties as (
    select b.geom,
           b.state,
           b.county,
           b.fips_code,
           avg(value)            as vaccine_value,
           sum(sample_size)      as sample_size
    from covid19_vaccine_accept_us a
             join us_counties_boundary b
                  on a.geo_value = b.fips_code
    group by 1, 2, 3, 4
);

create index on covid19_vaccine_accept_us_counties using gist (geom);
alter table covid19_vaccine_accept_us_counties set (parallel_workers = 32);