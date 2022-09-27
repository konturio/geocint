drop table if exists isodist_charging_stations_h3_distinct;
create table isodist_charging_stations_h3_distinct as (
    select h3, 
           min(distance) as distance, 
           geom
    from isochrone_destinations_h3_r8
    where type = 'charging_station'
    group by h3, geom
    order by h3
);
create index on isodist_charging_stations_h3_distinct using gist (geom);

drop table if exists isodist_charging_stations_h3;
create table isodist_charging_stations_h3 as (
    select p.h3, 8 as resolution, d.distance, (p.population * d.distance / 1000) as man_distance
    from kontur_population_h3 p
             cross join lateral (
        select (s.distance + ST_Distance(p.h3::geography, s.h3::geography)) as distance
        from isodist_charging_stations_h3_distinct s
        order by p.h3::geometry <-> s.geom
        limit 1
        ) d
    where p.resolution = 8
);
