drop table if exists wb_gadm_gdp_countries;
create table wb_gadm_gdp_countries as (
    select
        b.gid,
        b.gid_0              as code,
        b.name_0             as name,
        g.gdp                as gdp,
        g.year               as gdp_year,
        ST_Subdivide(b.geom) as geom
    from gadm_countries_boundary b
         join lateral (select gdp, year from wb_gdp g where g.code = b.gid_0 order by year desc limit 1) g on true
    
    -- WB calculates The Åland Islands as a part of Finland, but it's a separate entity
    -- on 0 adm level in GADM, so add it as a part of Finland
    union all
    select
        b.gid,
        'FIN'                as code,
        'Finland'            as name,
        g.gdp                as gdp,
        g.year               as gdp_year,
        ST_Subdivide(b.geom) as geom
    from (select * from gadm_countries_boundary where gid_0 = 'ALA') b
         join lateral (select gdp, year from wb_gdp g where g.code = 'FIN' order by year desc limit 1) g on true
);

vacuum analyse wb_gadm_gdp_countries;

create index on wb_gadm_gdp_countries using gist(geom);
