alter table osm_population_raw set (parallel_workers=32);
drop table if exists osm_population_raw_nowater;



drop table if exists tmp_osm_pop_split_for_water_trim;
create table tmp_osm_pop_split_for_water_trim as (
    select osm_type, osm_id, population, admin_level, ST_Subdivide(geom, 100) as geom
    from osm_population_raw
    order by geom );
alter table tmp_osm_pop_split_for_water_trim
    set (parallel_workers=32);
drop table if exists tmp_osm_population_raw_nowater;
create table tmp_osm_population_raw_nowater as (
    select p.geom as p_geom,
           ST_Collect(w.geom) as w_geom,
           p.osm_type,
           p.osm_id,
           p.population,
           p.admin_level
    from tmp_osm_pop_split_for_water_trim p
         left join osm_water_polygons w on ST_Intersects(w.geom, p.geom)
    group by p.osm_type, p.osm_id, p.population, p.admin_level, p.geom
);
drop table tmp_osm_pop_split_for_water_trim;
drop table if exists osm_population_raw_nowater;

alter table tmp_osm_population_raw_nowater
    set (parallel_workers=32);

create table osm_population_raw_nowater as (
    select population,
           osm_type,
           osm_id,
           admin_level,
           null::float as area,
           null::float as people_per_sq_km,
           ST_Collect(geom) as geom
    from (
             select population,
                    osm_type,
                    osm_id,
                    admin_level,
                    ST_Difference(p_geom, ST_UnaryUnion(w_geom)) as geom
             from tmp_osm_population_raw_nowater offset 0
         ) z
    group by 1, 2, 3, 4
);



drop table osm_population_raw;
alter table osm_population_raw_nowater rename to osm_population_raw;
delete from osm_population_raw where geom is null or ST_IsEmpty(geom);
update osm_population_raw set area = ST_Area(ST_Transform(geom, 4326)::geography) where area is null;
update osm_population_raw set people_per_sq_km = 1000000 * population / area where people_per_sq_km is null;
create index on osm_population_raw using gist(geom);
