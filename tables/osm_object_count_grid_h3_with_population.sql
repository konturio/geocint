drop table if exists h3_gdp_tmp;
create table h3_gdp_tmp as (
    select h.h3, sum(c.gdp * h.population * ST_Area(ST_Intersection(c.geom, h.geom)) / ST_Area(h.geom) / c.population_full)  as gdp_h3
      from osm_object_count_grid_h3_with_population_step1 h
        join countries_info c on ST_Intersects(c.geom, h.geom)
      where h.zoom = 8 and h.population > 0
      group by h.h3
);

drop table if exists osm_object_count_grid_h3_with_population;
create table osm_object_count_grid_h3_with_population as (
    select a.*,
           coalesce(p.gdp_h3,0) as gdp_h3
    from osm_object_count_grid_h3_with_population_step1 a
        full outer join h3_gdp_tmp g on g.h3 = a.h3
);

drop table osm_object_count_grid_h3_with_population_step1;
drop table if exists h3_gdp_tmp;

create index on osm_object_count_grid_h3_with_population using gist (geom, zoom);

vacuum osm_object_count_grid_h3_with_population;
