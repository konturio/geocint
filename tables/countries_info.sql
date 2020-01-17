drop table if exists tmp_countries_info;

create table tmp_countries_info as ( 
    select g.gid, g.gid_0 as code, g.name_0 as name, ST_Subdivide(g.geom) as geom
      from gadm_countries_boundary g
);

create table tmp2_countries_info as (
    select c.gid, c.code, c.name, c.geom, sum(a.people) as population
      from tmp_countries_info c
        left outer join population_vector a on ST_Intersects(a.geom, c.geom)
      where ST_Intersects(a.geom, c.geom)
      group by c.gid, c.code, c.name, c.geom
);

drop table if exists tmp_countries_info;

alter table tmp2_countries_info add column population_full float;
update tmp2_countries_info c set population_full = (select sum(a.population) from tmp2_countries_info a where a.code = c.code);

create table tmp3_countries_info as (
    select c.gid, c.code, c.name, c.geom, c.population, sum(a.population) as population_full, (select max(b.year) from wb_gdp b where b.code = c.code) as year
      from tmp2_countries_info c
        left outer join tmp2_countries_info a on a.code = c.code
        left outer join wb_gdp g on c.code = g.code
      where a.code = c.code
      group by c.gid, c.code, c.name, c.geom, c.population
);

create table countries_info as (
    select c.gid, c.code, c.name, c.geom, c.population, c.population_full, (select max(b.year) from wb_gdp b where b.code= c.code) as year
      from tmp3_countries_info c
);
drop table if exists tmp2_countries_info;

alter table countries_info add column gdp_full float;

update countries_info c set gdp_full = (select a.gdp from wb_gdp a where a.year = c.year and a.code = c.code);

alter table countries_info add column gdp float;

update countries_info set gdp = gdp_full * population / population_full;

drop table if exists tmp4_countries_info;

create index on countries_info using gist(geom);
