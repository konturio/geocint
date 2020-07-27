drop table if exists population_grid_h3_r8_points;
create table population_grid_h3_r8_points as (
    select p.*,
           h3_to_geometry(h3) as geom
    from population_grid_h3_r8 p
);

create index on population_grid_h3_r8_points using gist (geom);

-- сheck duplicates osm_id  from osm_population_raw
--
-- select osm_id, count(*)
-- from osm_population_raw
-- group by 1
-- having count(*) > 1;

-- TODO: add osm_type to osm_id

-- see max vertices in osm_population_raw polygons

-- select max(st_npoints(geom))
--     from osm_population_raw;

create table osm_population_raw_subdivided as (
    select osm_id,
           osm_type,
           st_subdivide(geom, 100) as geom
    from osm_population_raw
);

create index on osm_population_raw_subdivided using gist (geom);

alter table population_grid_h3_r8_points
    set (parallel_workers = 32);

create table population_grid_h3_r8_new as (
    select p.*,
           osm_id
    from population_grid_h3_r8_points p
             left join osm_population_raw_subdivided o
                       on st_intersects(p.geom, o.geom)
);

-- groups on osm_id by with sum_population

create table osm_population_raw_sum as (
    select osm_id, sum(population) as population
    from population_grid_h3_r8_new
    group by 1
);

create index on osm_population_raw_sum (osm_id) include (population);

drop table if exists population_grid_h3_upd;
create table population_grid_h3_upd as (
    select p.*,
           o_sum.osm_id     as osm_id_sum,
           o_sum.population as sum_population_h3
    from population_grid_h3_r8_new p
             left join osm_population_raw_sum as o_sum on p.osm_id = o_sum.osm_id
             left join osm_population_raw opr on o_sum.osm_id = opr.osm_id
);

create index on population_grid_h3_upd using gist (geom);

alter table population_grid_h3_upd
    set (parallel_workers = 32);

drop table if exists population_grid_h3;
create table population_grid_h3 as (
    select p.h3,
           p.resolution,
           p.geom,
           p.population::float * pu.population::float * ST_Area(pu.geom)::float / pu.sum_population_h3::float *
           ST_Area(ST_Intersection(pu.geom, p.geom))::float as population_new
    from population_grid_h3_r8_points p
             left join population_grid_h3_upd pu on ST_Intersects(pu.geom, p.geom)
--      group by p.h3, p.resolution, p.geom
);
