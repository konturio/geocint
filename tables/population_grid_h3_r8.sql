-- commented out WorldPop population dataset
drop table if exists population_grid_h3_r8_in;
create table population_grid_h3_r8_in as (
    select h3,
           h3::geometry              as geom,
           8                         as resolution,
           null::float               as population,
           coalesce(sum(ghs_pop), 0) as ghs_pop,
           sum(hrsl_pop)             as hrsl_pop
           --sum(worldpop)             as worldpop,
    from (
             select h3,
                    population  as ghs_pop,
                    null::float as hrsl_pop
                    --null::float as worldpop
             from ghs_globe_population_grid_h3_r8
             union all
             select h3,
                    null::float as ghs_pop,
                    population  as hrsl_pop
                    --null::float as worldpop
             from hrsl_population_grid_h3_r8
--              union all
--              select h3,
--                     null::float as ghs_pop,
--                     null::float as hrsl_pop,
--                     population  as worldpop
--              from worldpop_population_raster_grid_h3_r8
         ) z
    group by 1
);

create index on population_grid_h3_r8_in using gist (geom, hrsl_pop); --, worldpop);

drop table if exists population_grid_h3_r8;
create table population_grid_h3_r8 as (
    select h3,
           p.geom,
           resolution,
           population,
           ghs_pop,
           case when b.geom is not null then coalesce(p.hrsl_pop, 0) end as hrsl_pop
           --worldpop
    from population_grid_h3_r8_in p
             left outer join
         hrsl_population_boundary b
         on ST_Intersects(b.geom, p.geom)
);

drop table population_grid_h3_r8_in;

-- update population_grid_h3_r8 p
-- set worldpop = 0
-- from worldpop_population_boundary b
-- where ST_Intersects(ST_Transform(b.geom, 4326), p.geom)
--   and worldpop is null;

update population_grid_h3_r8 p
-- set population counts starting with more high resolution raster data (30m, 100m and whole planet)
-- IMPORTANT: worldpop removed from coalesce
set population = coalesce(hrsl_pop, ghs_pop);

vacuum full analyze population_grid_h3_r8;
create index on population_grid_h3_r8 using gist (geom, population);