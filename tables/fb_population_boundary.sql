drop table if exists fb_population_boundary;
create table fb_population_boundary as (
    select g.gid, g.gid_0 as iso, g.name_0 as name, ST_Subdivide(geom) as geom
    from gadm_countries_boundary g
             inner join fb_country_codes c on c.code = g.gid_0
);
