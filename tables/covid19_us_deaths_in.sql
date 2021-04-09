drop table if exists covid19_us_deaths_in;
create table covid19_us_deaths_in as
    select replace(fips, '.0', '') as fips,
           max(date) as date,
           sum(value) as value,
           combined_key,
           'dead'::text as status
 from covid19_us_deaths_csv_in group by 1, 4;