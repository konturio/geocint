-- Match WB gdp data with geometry boundaries with hasc code
drop table if exists wb_gdp_countries;
create table wb_gdp_countries as (
    with input as (
        (select distinct on (h.code)
                h.code       as code,
                h.country    as name,
                h.gdp        as gdp,
                h.year       as gdp_year,
                k.population as county_population,
                k.geom       as geom
        from kontur_boundaries_v4 as k
             inner join wb_gdp as h on h.hasc = k.hasc_wiki
        where h.gdp is not null
        order by h.code, gdp_year desc)
        union all
        -- IRL Guernsey and Jersey are the separate admin units
        -- but WB calculates them together as a Channel Islands
        (select distinct on (h.code)
                h.code          as code,
                h.country       as name,
                h.gdp           as gdp,
                h.year          as gdp_year,
                sum(population) as county_population,
                ST_Union(geom)  as geom
        from kontur_boundaries_v4 as k,
             wb_gdp as h 
        where k.hasc_wiki in ('GG', 'JE')
              and h.code = 'CHI'
              and h.gdp is not null
        group by 1,2,3,4
        order by h.code, gdp_year desc))
    select code,
           name,
           gdp,
           gdp_year,
           county_population,
           ST_Subdivide(ST_Transform(geom,3857)) as geom
    from input
);

vacuum analyse wb_gdp_countries;

create index on wb_gdp_countries using gist(geom);

drop table if exists gdp_h3;
create table gdp_h3 as (
    select distinct on (h3) h3,
                            8 as resolution,
                            gdp
    from (select h.h3,
                 c.county_population,
                 sum(c.gdp * h.population * ST_Area(ST_Intersection(c.geom, h.geom)) / ST_Area(h.geom) /
                     c.county_population) as gdp
          from kontur_population_h3 h
              join wb_gdp_countries c on ST_Intersects(c.geom, h.geom)
          where resolution = 8
          group by h.h3, c.code, c.county_population) a
    order by h3, county_population asc
);

call generate_overviews('gdp_h3', '{gdp}'::text[], '{sum}'::text[], 8);
