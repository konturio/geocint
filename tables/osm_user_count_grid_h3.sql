drop table if exists osm_user_count_grid_h3;
create table osm_user_count_grid_h3 as (
    select resolution,
           h3,
           osm_user,
           count(*) as count
    from (
             select resolution as resolution,
                    h3         as h3,
                    osm_user   as osm_user
             from osm,
                  ST_H3Bucket(geog) as hex
             where ts > (select max(ts) - interval '2 years' from osm)
         ) z
    group by 1, 2, 3
);
--create index on osm_user_count_grid_h3(osm_user, h3, resolution, count);


drop table if exists osm_user_object_count;
create table osm_user_object_count as (
    select osm_user,
           sum(count) as count
    from osm_user_count_grid_h3
    where resolution = 0
    group by osm_user
);
--create index on osm_user_object_count(osm_user, count);
--vacuum analyse osm_user_object_count;

drop table if exists osm_user_grid_h3;
create table osm_user_grid_h3 as (
    select distinct on (resolution, h3) resolution,
                                        h3,
                                        osm_user,
                                        count
    from osm_user_count_grid_h3
    order by resolution, h3, count desc
);

drop table if exists osm_user_count_grid_h3_normalized;
create table osm_user_count_grid_h3_normalized as (
    select resolution,
           h3,
           sum(g.count::float / u.count) as user_count
    from osm_user_count_grid_h3 g
             join osm_user_object_count u on g.osm_user = u.osm_user
    group by 1, 2
);
alter table osm_user_count_grid_h3_normalized
    set (parallel_workers = 32);

drop table if exists osm_user_count_grid_h3_normalized_population;
create table osm_user_count_grid_h3_normalized_population as (
    select coalesce(a.resolution, b.resolution) as resolution,
           coalesce(a.h3, b.h3)                 as h3,
           coalesce(a.user_count, 0)            as user_count,
           coalesce(b.population, 0)            as population
    from osm_user_count_grid_h3_normalized a
             full outer join population_grid_h3 b on a.resolution = b.resolution and a.h3 = b.h3
);

drop table if exists osm_user_count_grid_h3_normalized_geom;
create table osm_user_count_grid_h3_normalized_geom as (
    select resolution,
           h3,
           area / 1000000 as area_km2,
           geom           as geom,
           user_count,
           population
    from osm_user_count_grid_h3_normalized_population a
             join ST_HexagonFromH3(h3) hex on true
);