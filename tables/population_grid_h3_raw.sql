drop table if exists population_grid_h3_r8_points;
create table population_grid_h3_r8_points as (
    select p.*,
           h3_to_geometry(h3) as geom
    from population_grid_h3_r8 p
);

create index on population_grid_h3_r8_points using gist (geom);

drop table if exists population_grid_h3_raw;
create table population_grid_h3_raw as (
    select p.resolution,
           p.geom,
           p.population,
           p.h3,
           o.population as pop
    from population_grid_h3_r8_points p
             left outer join
         osm_population_raw o on true
    where st_intersects(p.geom, o.geom)
);

drop table if exists population_grid_h3_reb;
create table population_grid_h3_reb as (
    select p.h3,
           p.resolution,
           p.geom,
           p.population * o.population * ST_Area(p.geom) / population_sum *
           ST_Area(ST_Intersection(o.geom, p.geom)) as population_new
    from population_grid_h3 p
             join osm_population_raw o on ST_Intersects(o.geom, p.geom)
    group by o.population, p.h3, p.resolution, p.geom, p.population, o.geom
);
