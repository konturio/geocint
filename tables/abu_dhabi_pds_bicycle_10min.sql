drop table if exists abu_dhabi_pds_bicycle_10min;
create table abu_dhabi_pds_bicycle_10min as (
    select p1.id,
           p1.height,
           p1.population,
           sum(p2.volume)              "volume",
           sum(p2.population)          "pds",
           ST_Transform(p1.geom, 4326) "geom"
    from abu_dhabi_buildings_population p1,
         abu_dhabi_isochrones_bicycle_10m isochrone,
         abu_dhabi_buildings_population p2
    where p1.id = isochrone.building_id
      and ST_Intersects(isochrone.geom, p2.geom)
    group by p1.id, p1.height, p1.population, p1.geom
);