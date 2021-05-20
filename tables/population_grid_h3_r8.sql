drop table if exists population_grid_h3_r8;
create table population_grid_h3_r8 as (
    select h3,
           h3::geometry  as geom,
           8             as resolution,
           null::float   as population,
           sum(ghs_pop)  as ghs_pop,
           sum(hrsl_pop) as hrsl_pop,
           sum(worldpop) as worldpop
    from (
             select h3,
                    population  as ghs_pop,
                    null::float as hrsl_pop,
                    null::float as worldpop
             from ghs_globe_population_grid_h3_r8
             union all
             select h3,
                    null::float as ghs_pop,
                    population  as hrsl_pop,
                    null::float as worldpop
             from hrsl_population_grid_h3_r8
             union all
             select h3,
                    null::float as ghs_pop,
                    null::float as hrsl_pop,
                    null::float as worldpop
             from fb_population_grid_h3_r8
             union all
             select h3,
                    null::float as ghs_pop,
                    null::float as hrsl_pop,
                    population  as worldpop
             from worldpop_population_raster_grid_h3_r8
         ) z
    group by 1
);

update population_grid_h3_r8 p
set ghs_pop = 0
where ghs_pop is null;

create index population_grid_h3_r8_geom_hrsl_pop_worldpop_idx on population_grid_h3_r8 using gist (geom, hrsl_pop, worldpop);

update population_grid_h3_r8 p
set hrsl_pop = 0
from hrsl_population_boundary b
where ST_Intersects(ST_Transform(b.geom, 4326), p.geom)
  and hrsl_pop is null;
vacuum population_grid_h3_r8;

update population_grid_h3_r8 p
set worldpop = 0
from worldpop_population_boundary b
where ST_Intersects(ST_Transform(b.geom, 4326), p.geom)
  and worldpop is null;

drop index population_grid_h3_r8_geom_hrsl_pop_worldpop_idx;
vacuum population_grid_h3_r8;
update population_grid_h3_r8 p
-- set population counts starting with more high resolution raster data (30m, 100m and whole planet)
set population = coalesce(hrsl_pop, worldpop, ghs_pop);

vacuum full population_grid_h3_r8;
vacuum analyze population_grid_h3_r8;
create index on population_grid_h3_r8 using gist (geom, population);
alter table population_grid_h3_r8
    set (parallel_workers = 32);
