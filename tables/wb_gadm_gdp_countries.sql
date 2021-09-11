drop table if exists wb_gadm_gdp_countries;

create table wb_gadm_gdp_countries as (
    select
        b.gid,
        b.gid_0 as code,
        b.name_0 as name,
        g.gdp as gdp,
        g.year as gdp_year,
        ST_Subdivide(b.geom) as geom
    from
        gadm_countries_boundary                                                                         b
        join lateral (select gdp, year from wb_gdp g where g.code = b.gid_0 order by year desc limit 1) g on true
);


vacuum analyse wb_gadm_gdp_countries;