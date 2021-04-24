drop table if exists covid19_us_deaths_in;
create table covid19_us_deaths_in as
(select
        case
            when length(fips) = 6
            then '0'::text||(replace(fips, '.0', ''))::text
            else replace(fips, '.0', '')
        end as fips,
        max(date) as date,
        max(value) as value,
        combined_key,
        'dead'::text as status
 from covid19_us_deaths_csv_in group by 1, 4);