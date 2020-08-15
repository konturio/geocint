drop table if exists population_grid_h3_r8;
create table population_grid_h3_r8 as (
    select
        h3,
        h3::geometry as centroid,
        8 as resolution,
        null::float as population,
        sum(ghs_pop) as ghs_pop,
        sum(hrsl_pop) as hrsl_pop,
        sum(fb_africa_pop) as fb_africa_pop,
        sum(fb_pop) as fb_pop
    from
        (
            select
                h3, population as ghs_pop, null::float as hrsl_pop,
                null::float as fb_africa_pop, null::float as fb_pop
            from
                ghs_globe_population_grid_h3_r8
            union all
            select
                h3, null::float as ghs_pop, population as hrsl_pop,
                null::float as fb_africa_pop, null::float as fb_pop
            from
                hrsl_population_grid_h3_r8
            union all
            select
                h3, null::float as ghs_pop, null::float as hrsl_pop,
                population as fb_africa_pop, null::float as fb_pop
            from
                fb_africa_population_grid_h3_r8
            union all
            select
                h3, null::float as ghs_pop, null::float as hrsl_pop,
                null::float as fb_africa_pop, population as fb_pop
            from
                fb_population_grid_h3_r8
        ) z
    group by 1
);
update population_grid_h3_r8 p
set
    ghs_pop = 0
where ghs_pop is null;

create index on population_grid_h3_r8 using gist (centroid, hrsl_pop, fb_africa_pop, fb_pop);

update population_grid_h3_r8 p
set
    hrsl_pop = 0
from
    hrsl_population_boundary b
where
      ST_Intersects(ST_Transform(b.geom, 4326), p.centroid)
  and hrsl_pop is null;
vacuum population_grid_h3_r8;
update population_grid_h3_r8 p
set
    fb_africa_pop = 0
from
    fb_africa_population_boundary b
where
      ST_Intersects(ST_Transform(b.geom, 4326), p.centroid)
  and fb_africa_pop is null;
vacuum population_grid_h3_r8;
update population_grid_h3_r8 p
set
    fb_pop = 0
from
    fb_population_boundary b
where
      ST_Intersects(ST_Transform(b.geom, 4326), p.centroid)
  and fb_pop is null;
drop index population_grid_h3_r8_centroid_hrsl_pop_fb_africa_pop_fb_po_idx;
vacuum population_grid_h3_r8;
update population_grid_h3_r8 p set population = coalesce(fb_pop, fb_africa_pop, hrsl_pop, ghs_pop);
vacuum full population_grid_h3_r8;
vacuum analyze population_grid_h3_r8;