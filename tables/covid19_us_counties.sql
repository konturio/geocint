drop table if exists covid19_us_counties;
create table covid19_us_counties as (
    select b.admin_id,
           b.geom,
           b.state,
           b.county,
           b.fips_code,
           value,
		   time_value,
		   status
    from covid19_us_counties_in a
             join us_counties_boundary b
                  on a.geo_value = b.fips_code
    where a.value > 0
);
create index on covid19_us_counties using gist (geom);
alter table covid19_us_counties set (parallel_workers = 32);