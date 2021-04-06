drop table if exists covid19_us_counties;

create index if not exists covid19_us_confirmed_in_fips_idx on covid19_us_confirmed_in (fips);

create table covid19_us_counties as (
    select b.admin_id,
           b.geom,
           b.state,
           b.county,
           b.fips_code,
           a.value,
		   a.date,
		   a.status,
           null::int as population
    from covid19_us_confirmed_in a
             join us_counties_boundary b
                  on a.fips = b.fips_code
);

create index if not exists covid19_us_deaths_in_fips_idx on covid19_us_deaths_in (fips);

insert into covid19_us_counties (admin_id, geom, state, county, fips_code, value, date, status, population)
    select b.admin_id,
           b.geom,
           b.state,
           b.county,
           b.fips_code,
           a.value,
		   a.date,
		   a.status,
           a.population as population
    from covid19_us_deaths_in a
             join us_counties_boundary b
                  on a.fips = b.fips_code
);

create index on covid19_us_counties using gist (geom);
alter table covid19_us_counties set (parallel_workers = 32);
