drop table if exists osm_object_count_grid_h3_with_population_tmp;
create table osm_object_count_grid_h3_with_population_tmp as (
    select coalesce(a.resolution, b.resolution) as resolution,
           coalesce(a.resolution, b.resolution) as zoom,
           coalesce(a.h3, b.h3)                 as h3,
           coalesce(a.count, 0)                 as count,
           coalesce(building_count, 0)          as building_count,
           coalesce(highway_length, 0)          as highway_length,
           coalesce(amenity_count, 0)           as amenity_count,
           coalesce(osm_users, 0)               as osm_users,
           coalesce(c.user_count, 0)            as osm_users_recent,
           coalesce(c.user_count_normalized_objects, 0) as osm_user_count_normalized_objects,
           coalesce(c.user_count_normalized_hours, 0) as osm_user_count_normalized_hours,
           d.osm_user                           as top_user,
           d.count                              as top_user_objects,
           coalesce(population, 0)              as population,
           avg_ts                               as avg_ts,
           max_ts                               as max_ts,
           p90_ts                               as p90_ts
    from osm_object_count_grid_h3 a
             full join population_grid_h3 b on a.resolution = b.resolution and a.h3 = b.h3
             left join osm_user_count_grid_h3_normalized c on a.resolution = c.resolution and a.h3 = c.h3
             left join osm_user_grid_h3 d on a.resolution = d.resolution and a.h3 = d.h3
    order by 1, 2
);

drop table if exists osm_object_count_grid_h3_with_population;
create table osm_object_count_grid_h3_with_population as (
    select a.*,
           hex.area / 1000000.0 as area_km2,
           hex.geom             as geom
    from osm_object_count_grid_h3_with_population_tmp a
             join ST_HexagonFromH3(h3) hex on true
);

drop table osm_object_count_grid_h3_with_population_tmp;

vacuum analyze osm_object_count_grid_h3_with_population;
create index on osm_object_count_grid_h3_with_population using gist (geom, zoom);
