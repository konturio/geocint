alter table osm_population_raw set (parallel_workers=32);
drop table if exists osm_population_raw_nowater;

create table osm_population_raw_nowater as (
    select
        coalesce(ST_Difference(p.geom, ST_Union(w.geom)), p.geom) as geom,
        p.osm_type,
        p.osm_id,
        null::float                                               as area,
        p.population,
        null::float                                               as people_per_sq_km,
        p.admin_level
    from
        osm_population_raw p
            left join osm_water_polygons w on (ST_Intersects(w.geom, p.geom))
    group by p.geom, p.osm_type,  p.osm_id, p.population, p.admin_level
);
drop table osm_population_raw;
alter table osm_population_raw_nowater rename to osm_population_raw;
delete from osm_population_raw where geom is null or ST_IsEmpty(geom);
update osm_population_raw set area = ST_Area(ST_Transform(geom, 4326)::geography) where area is null;
update osm_population_raw set people_per_sq_km = 1000000 * population / area where people_per_sq_km is null;
create index on osm_population_raw using gist(geom);
