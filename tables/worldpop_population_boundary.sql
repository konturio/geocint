drop table if exists worldpop_population_boundary;
create table worldpop_population_boundary as (
    select g.gid,
           g.gid_0            as iso,
           g.name_0           as name,
           ST_Subdivide(geom) as geom
-- TODO: should we use GADM boundaries for WorldPop based on article about Population Density Rasters from 2017?
    from gadm_countries_boundary g,
         worldpop_country_codes c
    where c.code = g.gid_0
);
