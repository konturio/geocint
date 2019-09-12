drop table if exists osm_user_count_grid_h3;
create table osm_user_count_grid_h3 as (
    select resolution,
           h3,
           osm_user,
           count(*)      as count,
           min(ts_epoch) as min_ts,
           max(ts_epoch) as max_ts
    from (
             select resolution             as resolution,
                    h3                     as h3,
                    osm_user               as osm_user,
                    extract(epoch from ts) as ts_epoch
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


select _ST_DistanceTree(
           '0103000020E610000001000000070000003718F1670B59F3BF883CC6864FCE2F406A7A568D7E50F3BFE282195C13C82F40A762DD24A921F3BF3D47633362C52F40D8BDC49F5DFBF2BFA08CBF32EDC82F40600DC59AE803F3BF33FDA1A229CF2F401FB898FAC032F3BF097FF2CDDAD12F403718F1670B59F3BF883CC6864FCE2F40'::geography,
           'SRID=4326;LINESTRING(0 -87, 0 87)'::geography);