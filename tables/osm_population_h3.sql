drop table if exists osm_population_raw_h3_r8;
create table osm_population_raw_h3_r8 as (
    select h3_geo_to_h3(ST_Transform(ST_Centroid(geom), 4326)::point, 8) as h3,
           8                                                             as resolution,
           sum(population)                                               as population_raw,
           sum(people_per_sq_km)                                         as people_per_sq_km
    from osm_population_raw
    group by 1, admin_level);

drop table if exists osm_population_raw_in;
create table osm_population_raw_in as (
    select o.*,
           hex.area / 1000000.0 as area_km2,
           hex.geom             as geom
    from osm_population_raw_h3_r8 o
             join ST_HexagonFromH3(h3) hex on true
);

drop table if exists osm_population_raw_h3;
create table osm_population_raw_h3 as (
    select h.h3,
           h.resolution,
           h.geom,
           coalesce(o.population_raw * h.population / nullif(sum(population_raw), 0), 0) as population_osm
    from kontur_population_h3 h
             join osm_population_raw_in o on ST_Intersects(o.geom, h.geom)
    group by o.h3, h.h3, h.resolution,
             h.geom, o.population_raw, h.population
);
