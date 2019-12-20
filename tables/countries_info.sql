drop table if exists countries_info;

create table countries_info as ( select gid, gid_0 as code, name_0 as name, geom from gadm_countries_boundary );

alter table countries_info add column year integer;
alter table countries_info add column gdp float;
alter table countries_info add column population float;

update countries_info c set year = (select a.year from wb_gdp a where a.year = (select max(b.year) from wb_gdp b where b.code= a.code) and a.code = c.code);
update countries_info c set gdp = (select a.gdp from wb_gdp a where a.year = (select max(b.year) from wb_gdp b where b.code= a.code) and a.code = c.code);
update countries_info c set population = (select sum(a.people) from population_vector_nowater a where ST_Intersects(a.geom, c.geom));
