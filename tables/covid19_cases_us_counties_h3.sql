alter table covid19_cases_us_counties
    set (parallel_workers = 32);

drop table if exists covid19_cases_us_counties_h3;
create table covid19_cases_us_counties_h3 as (
    select h3_geo_to_h3(ST_Transform(ST_Centroid(geom), 4326)::point, 8) as h3,
           8                                                             as resolution,
           sum(cases_value)                                              as cases_value
    from covid19_cases_us_counties
    group by 1);

alter table covid19_cases_us_counties_h3
    set (parallel_workers = 32);

do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into covid19_cases_us_counties_h3 (h3, cases_value, resolution)
                select h3_to_parent(h3) as h3, sum(cases_value) as cases_value, (res - 1) as resolution
                from covid19_cases_us_counties_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;
