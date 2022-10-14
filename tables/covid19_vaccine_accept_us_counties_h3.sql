drop table if exists covid19_vaccine_accept_us_counties_h3_in;
create table covid19_vaccine_accept_us_counties_h3_in as (
    select distinct on (h3_polygon_to_cells((geom), 8)) h3_polygon_to_cells((geom), 8) as h3,
           h3_cell_to_geometry(h3_polygon_to_cells(geom, 8))                        as geom,
           fips_code
    from covid19_vaccine_accept_us_counties
    order by 1
);

create index on covid19_vaccine_accept_us_counties_h3_in using gist(geom);

drop table if exists covid19_vaccine_accept_us_counties_h3;
create table covid19_vaccine_accept_us_counties_h3 as (
    select h3_polygon_to_cells((geom), 8)              as h3,
           vaccine_value / h3_count            as vaccine_value,
           8::int                              as resolution
    from covid19_vaccine_accept_us_counties u,
    lateral (select u.fips_code, count(h3) as h3_count
             from covid19_vaccine_accept_us_counties_h3_in h
             where ST_Intersects(h.geom, u.geom)
    group by 1) x
    where x.fips_code = u.fips_code
);
