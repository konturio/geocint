drop table if exists population_grid_h3_r8_points;
create table population_grid_h3_r8_points as (
    select p.*,
           h3_to_geometry(h3) as geom
    from population_grid_h3_r8 p
);

create index on population_grid_h3_r8_points using gist (geom);

-- сheck duplicates osm_id from osm_population_raw

-- TODO: add osm_type to osm_id

-- subdividing osm_population_raw polygons into smaller ones from easier intersections later

drop table if exists osm_population_raw_subdivided;
create table osm_population_raw_subdivided as (
    select osm_id,
           osm_type,
           st_subdivide(geom, 100) as geom
    from osm_population_raw
);

create index on osm_population_raw_subdivided using gist (geom);

alter table population_grid_h3_r8_points
    set (parallel_workers = 32);

-- osm_id for every h3 polygon

drop table if exists population_grid_h3_r8_new;
create table population_grid_h3_r8_new as (
    select p.*,
           osm_id
    from population_grid_h3_r8_points p
             left join osm_population_raw_subdivided o
                       on ST_Intersects(p.geom, o.geom)
);

-- groups by osm_id by with sum_population

drop table if exists osm_population_raw_sum;
create table osm_population_raw_sum as (
    select osm_id, sum(population) as population
    from population_grid_h3_r8_new
    group by 1
);

create index on osm_population_raw_sum (osm_id) include (population);

-- h3 knows his full sum population from every osm_population_raw polygon he intersects

drop table if exists population_grid_h3_upd;
create table population_grid_h3_upd as (
    select p.*,
           o_sum.osm_id     as osm_id_sum,
           o_sum.population as sum_population_h3
    from population_grid_h3_r8_new p
             left join osm_population_raw_sum as o_sum on p.osm_id = o_sum.osm_id
             left join osm_population_raw opr on p.osm_id = opr.osm_id
);

create index on population_grid_h3_upd using gist (geom);

alter table population_grid_h3_upd
    set (parallel_workers = 32);

-- put osm_population_raw into population_grid_h3_r8 model

drop table if exists population_grid_h3_r8_osm_scaled;
create table population_grid_h3_r8_osm_scaled as (
    select pop.h3,
           pop.resolution,
           pop.geom,
           pop.population::float * osm.population::float / pop.sum_population_h3::float as population
    from population_grid_h3_upd pop
             join osm_population_raw osm on pop.osm_id = osm.osm_id
);

create index on population_grid_h3_r8_osm_scaled using gist (geom);
