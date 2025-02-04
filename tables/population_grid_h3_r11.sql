-- commented out WorldPop population dataset
drop table if exists population_grid_h3_r11_in;
create table population_grid_h3_r11_in as (
    select h3,
           h3::geometry              as geom,
           11                        as resolution,                      
           coalesce(sum(ghs_pop), 0) as ghs_pop,
           sum(hrsl_pop)             as hrsl_pop,
           sum(wsf_pop)              as wsf_pop
    from (
              select h3,
                     population  as ghs_pop,
                     null::float as hrsl_pop,
                     null::float as wsf_pop
              from ghs_globe_population_grid_h3_r11
              union all
              select h3,
                     null::float as ghs_pop,
                     population  as hrsl_pop,
                     null::float as wsf_pop
              from hrsl_population_grid_h3_r11
              union all
              select h3,                    
                     null::float as ghs_pop,
                     null::float as hrsl_pop,
                     population as wsf_pop
              from wsf_population_h3
              where resolution = 11
         ) z
    group by 1
);

create index on population_grid_h3_r11_in using gist (geom, hrsl_pop);
create index on population_grid_h3_r11_in using btree (h3);

drop table if exists population_grid_h3_r11;
create table population_grid_h3_r11 as (
    select p.h3,
           p.geom,
           p.resolution,
           null::float as population,
           case 
               when f.h3 is null 
                   then coalesce(p.ghs_pop, 0)
           end         as ghs_pop,
           case 
               when b.geom is not null and f.h3 is null 
                   then coalesce(p.hrsl_pop, 0)
           end         as hrsl_pop,
           wsf_pop
    from population_grid_h3_r11_in p
         left outer join hrsl_population_boundary b on ST_Intersects(b.geom, p.geom)
         left outer join wsf_mask f on p.h3 = f.h3
);

drop table population_grid_h3_r11_in;

update population_grid_h3_r11 p
-- set population counts starting with more high resolution raster data (30m, 100m and whole planet)
set population = coalesce(wsf_pop, hrsl_pop, ghs_pop);

vacuum full analyze population_grid_h3_r11;
create index on population_grid_h3_r11 using gist (geom, population);
create index on population_grid_h3_r11 using btree (h3);
