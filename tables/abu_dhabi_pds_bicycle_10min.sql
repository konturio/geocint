drop table if exists abu_dhabi_pds_bicycle_10min;
create table abu_dhabi_pds_bicycle_10min as (
    select p1.id, p1.population, sum(p2.population) "pds", p1.geom
    from abu_dhabi_buildings_population p1,
         abu_dhabi_isochrones_bicycle_10m isochrone,
         abu_dhabi_buildings_population p2
    where p1.id = isochrone.building_id
    and ST_Intersects(isochrone.geom, p2.geom)
);