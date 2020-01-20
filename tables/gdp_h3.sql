drop table if exists countries_info;
create table countries_info as (
    select
        c.*,
        (
            select sum(a.population)
            from
                kontur_population_h3 a
            where
                  ST_Intersects(a.geom, c.geom)
              and a.resolution = 8
        ) as population
    from
        wb_gadm_gdp_countries c
);

drop table if exists tmp_countries_info;

alter table countries_info
    add column population_full float;

update countries_info c
set
    population_full = b.population_full
from (select code, sum(population) as population_full from countries_info group by 1) b
where b.code = c.code;
create index on countries_info using gist (geom);


drop table if exists gdp_h3;
create table gdp_h3 as (
    select
        h.h3,
        h.resolution,
        h.geom,
        sum(c.gdp * h.population * ST_Area(ST_Intersection(c.geom, h.geom)) / ST_Area(h.geom) /
            c.population_full) as gdp
    from
        kontur_population_h3 h
        join countries_info  c on ST_Intersects(c.geom, h.geom)
    group by h.h3, h.resolution, h.geom
);

