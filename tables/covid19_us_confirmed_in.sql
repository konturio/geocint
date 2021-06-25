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

insert into covid19_us_confirmed_in (fips, date, value, combined_key, status)
(select
        '49000' as fips,
        max(date) as date,
        max(cumulative_cases) as value,
        'Utah, US' as combined_key,
        'confirmed' as status
from covid19_utah_confirmed_csv_in);

delete from covid19_us_confirmed_in where fips like '490%' and not fips = '49000';

create index if not exists covid19_us_confirmed_in_fips_idx on covid19_us_confirmed_in (fips);