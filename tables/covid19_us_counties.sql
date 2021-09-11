drop table if exists covid19_us_counties_in;
create table covid19_us_counties_in as (
    select b.admin_id,
           b.geom,
           b.fips_code,
           a.value,
           a.date,
           a.status,
           null::int as population
    from covid19_us_confirmed_in a
             join us_counties_boundary b
                  on a.fips = b.fips_code
);

insert into covid19_us_counties_in (admin_id, geom, fips_code, value, date, status)
select b.admin_id,
       b.geom,
       b.fips_code,
       a.value,
       a.date,
       a.status
from covid19_us_deaths_in a
         join us_counties_boundary b
              on a.fips = b.fips_code;

drop table if exists covid19_us_counties;
create table covid19_us_counties as (
    select admin_id,
           fips_code,
           value,
           date,
           status,
           population,
           ST_Subdivide(geom) as geom
    from covid19_us_counties_in
);

drop table if exists covid19_us_counties_in;
create index on covid19_us_counties using gist (geom);
vacuum analyse covid19_us_counties;
