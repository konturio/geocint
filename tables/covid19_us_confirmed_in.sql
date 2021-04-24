drop table if exists covid19_us_confirmed_in;
create table covid19_us_confirmed_in as
(select
        case
            when length(fips) = 6
            then '0'::text||(replace(fips, '.0', ''))::text
            else replace(fips, '.0', '')
        end as fips,
        max(date) as date,
        max(value) as value,
        combined_key,
        'confirmed'::text as status
 from covid19_us_confirmed_csv_in group by 1, 4);
