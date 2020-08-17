-- subdividing osm_population_raw polygons into smaller ones from easier intersections later


create table osm_population_raw_centroid as (
    select osm_id, osm_type,
           population,
           h3_geo_to_h3(ST_PointOnSurface(geom),8) as h3,
           ST_PointOnSurface(geom) as geom
    from osm_population_raw
);


drop table if exists osm_population_raw_subdivided;
create table osm_population_raw_subdivided as (
    select osm_id,
           osm_type,
           ST_Subdivide(geom, 100) as geom
    from osm_population_raw
);

create index on osm_population_raw_subdivided using gist (geom);

-- osm_id for every h3 polygon

drop table if exists population_grid_h3_r8_new;
create table population_grid_h3_r8_new as (
    select resolution,
           h3,
           population,
           p.geom,
           osm_id
    from population_grid_h3_r8                   p
         left join osm_population_raw_subdivided o
                   on ST_Intersects(p.geom, o.geom)
);

-- groups by osm_id by with sum_population

drop table if exists osm_population_raw_sum;
create table osm_population_raw_sum as (
    select osm_id,
           sum(population) as population
    from population_grid_h3_r8_new
    group by 1
);

-- count h3 for every population polygon

drop table if exists osm_population_raw_h3;
create table osm_population_raw_h3 as (
    select o.osm_id,
           count(h3) as h3_count
    from osm_population_raw_sum            o
         join population_grid_h3_r8_new as p on o.osm_id = p.osm_id
    group by 1
);

-- create table with unique osm_id, sum population and counted h3 for every polygon with population

drop table if exists osm_population_raw_sum_h3;
create table osm_population_raw_sum_h3 as (
    select sum.osm_id,
           sum.population,
           h3.h3_count
    from osm_population_raw_sum     as sum
         join osm_population_raw_h3 as h3 on sum.osm_id = h3.osm_id
);

create index on osm_population_raw_sum_h3 (osm_id) include (population);

-- h3 knows his full sum population from every osm_population_raw polygon that he intersects

drop table if exists population_grid_h3_upd;
create table population_grid_h3_upd as (
    select resolution,
           h3,
           p.population,
           p.geom,
           p.osm_id,
           o_sum.osm_id as osm_id_sum,
           o_sum.population as sum_population_h3
    from population_grid_h3_r8_new              p
         left join osm_population_raw_sum_h3 as o_sum on p.osm_id = o_sum.osm_id
         left join osm_population_raw           opr on p.osm_id = opr.osm_id
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
    from population_grid_h3_upd  pop
         join osm_population_raw osm on pop.osm_id = osm.osm_id
);

create index on population_grid_h3_r8_osm_scaled using gist (geom);
