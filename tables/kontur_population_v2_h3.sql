drop table if exists kontur_population_v2_h3;
create table kontur_population_v2_h3 as (
    select h3_geo_to_h3(ST_PointOnSurface(geom), 8) as h3,
           8::integer                               as resolution,
           population
    from kontur_population_v2
);

do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into kontur_population_v2_h3 (h3, population, resolution)
                select h3_to_parent(h3) as h3, sum(population) as population, (res - 1) as resolution
                from kontur_population_v2_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;
