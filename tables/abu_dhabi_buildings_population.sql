drop table if exists abu_dhabi_buildings_population;
create table abu_dhabi_buildings_population as (
    with population as (
        select distinct p.*
        from abu_dhabi_admin_boundaries b,
             kontur_population_h3 p
        where p.resolution = 8
          and ST_Intersects(ST_Transform(b.geom, 3857), p.geom)
    ),
         population_volume as (
             select p.h3,
                    p.population,
                    p_4326 "geom",
                    sum(b.building_height * ST_Area(
                            ST_Intersection(b.geom, p_4326)::geography
                        )) "volume"
             from population p,
                  ST_Transform(p.geom, 4326) "p_4326"
                      left outer join
                  abu_dhabi_buildings b
                  on ST_Intersects(p_4326, b.geom)
             group by p.h3, p.population, p_4326
         )
    select b.id,
           round(sum(ST_Area(ST_Intersection(p.geom, b.geom)::geography) * b.building_height / volume *
                     population)) "population",
           b.geom
    from population_volume p,
         abu_dhabi_buildings b
    where ST_Intersects(p.geom, b.geom)
    group by b.id, b.geom
);