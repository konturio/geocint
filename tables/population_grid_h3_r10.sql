-- commented out WorldPop population dataset
drop table if exists population_grid_h3_r10_in;
create table population_grid_h3_r10_in as (
    select h3,
           h3::geometry              as geom,
           10                        as resolution,
           null::float               as population,
           coalesce(sum(ghs_pop), 0) as ghs_pop,
           sum(hrsl_pop)             as hrsl_pop
    from (
             select h3,
                    population  as ghs_pop,
                    null::float as hrsl_pop
             from ghs_globe_population_grid_h3_r10
             union all
             select h3,
                    null::float as ghs_pop,
                    population  as hrsl_pop
             from hrsl_population_grid_h3_r10
         ) z
    group by 1
);

create index on population_grid_h3_r10_in using gist (geom, hrsl_pop);

drop table if exists population_grid_h3_r10;
create table population_grid_h3_r10 as (
    select h3,
           p.geom,
           resolution,
           population,
           ghs_pop,
           case when b.geom is not null then coalesce(p.hrsl_pop, 0) end as hrsl_pop
    from population_grid_h3_r10_in p
             left outer join
         hrsl_population_boundary b
         on ST_Intersects(b.geom, p.geom)
);

drop table population_grid_h3_r10_in;

update population_grid_h3_r10 p
-- set population counts starting with more high resolution raster data (30m, 100m and whole planet)
set population = coalesce(hrsl_pop, ghs_pop);

vacuum full analyze population_grid_h3_r10;
create index on population_grid_h3_r10 using gist (geom, population);
create index on population_grid_h3_r10 using btree (h3);