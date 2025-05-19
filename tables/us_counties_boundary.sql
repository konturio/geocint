drop table if exists us_counties_boundary;
create table us_counties_boundary as (
    select gid_2 as gid,
           geom,
           state,
           county,
           hasc_code,
           fips_code
    from gadm_us_counties_boundary
             join us_counties_fips_codes on hasc_2 = hasc_code);

create sequence us_counties_boundary_admin_id_seq START 10001;
alter table us_counties_boundary
    add column admin_id integer NOT NULL DEFAULT nextval('us_counties_boundary_admin_id_seq');
alter sequence us_counties_boundary_admin_id_seq OWNED BY us_counties_boundary.admin_id;

--Utah
insert into us_counties_boundary (gid, geom, state, county, hasc_code, fips_code)
select 'USA.45', ST_Multi(ST_Union(geom)), 'Utah', '', 'US.UT', '49000'
from us_counties_boundary
where hasc_code like 'US.UT%';

create index on us_counties_boundary (fips_code);