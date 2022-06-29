drop table if exists kontur_population_export;

create table kontur_population_export as (
    select
        pop.h3,
        pop.population,
        hdx.hasc as location,
        pop.geom
    from kontur_population_h3 as pop,
        hdx_boundaries as hdx
    where
        pop.resolution = 8
        and ST_Intersects(pop.geom, ST_Transform(hdx.geom, 3857))
);

create index on kontur_population_export (location);