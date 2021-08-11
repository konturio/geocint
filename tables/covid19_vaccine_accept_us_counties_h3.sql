drop table if exists covid19_vaccine_accept_us_counties_h3;
create table covid19_vaccine_accept_us_counties_h3 as (
    select h3_polyfill(geom, 8) as h3,
           8                    as resolution,
           sum(vaccine_value)   as vaccine_value
    from covid19_vaccine_accept_us_counties
    group by 1);

alter table covid19_vaccine_accept_us_counties_h3
    set (parallel_workers = 32);
