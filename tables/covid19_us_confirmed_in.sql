drop table if exists covid19_us_confirmed_in;
create table covid19_us_confirmed_in as
    select replace(fips, '.0', '') as fips,
           max(date) as date,
           sum(value) as value,
           combined_key,
           'confirmed'::text as status
 from covid19_us_confirmed_csv_in group by 1, 4;