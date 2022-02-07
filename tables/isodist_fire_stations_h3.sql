drop table if exists isodist_fire_stations_h3_distinct;
create table isodist_fire_stations_h3_distinct as (
    select h3, min(distance) distance, geom
    from isochrone_destinations_h3_r8
    where type = 'fire_station'
    group by h3, geom
    order by h3
);
create index on isodist_fire_stations_h3_distinct using gist (geom);

drop table if exists isodist_fire_stations_h3;
create table isodist_fire_stations_h3 as (
    select h3, 8 resolution, min(distance) / 1000 distance
    from (
             select h3, distance
             from isodist_fire_stations_h3_distinct
             union all
             select g.h3, d.distance
             from osm_object_count_grid_h3 g
                  left outer join isodist_fire_stations_h3_distinct i
                     on (g.h3 = i.h3)
                  cross join lateral (
                 select s.h3, s.distance + ST_Distance(g.h3::geography, s.h3::geography) distance
                 from isodist_fire_stations_h3_distinct s
                 order by g.h3::geometry <-> s.geom
                 limit 1
                 ) d
             where g.highway_length > 0
               and g.resolution = 8
               and i.h3 is null
         ) f
    group by h3
);

drop table isodist_fire_stations_h3_distinct;

