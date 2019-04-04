drop table if exists osm_object_count_grid_1000_with_population;
create table osm_object_count_grid_1000_with_population as (
    select
        coalesce(a.geom, b.geom)                                                          as geom,
        coalesce(count, 0)                                                                as count,
        coalesce(building_count, 0)                                                       as building_count,
        coalesce(highway_count, 0)                                                        as highway_count,
        coalesce(highway_length, 0)                                                       as highway_length,
        coalesce(amenity_count, 0)                                                        as amenity_count,
        coalesce(natural_count, 0)                                                        as natural_count,
        coalesce(landuse_count, 0)                                                        as landuse_count,
        coalesce(population, 0)                                                           as population,
        ST_Area(ST_Transform(coalesce(a.geom, b.geom), 4326)::geography)::float / 1000000 as area_km2
    from
        osm_object_count_grid_1000 a
            full outer join ghs_population_grid_1000 b on a.geom::bytea = b.geom::bytea
    order by 1
);
