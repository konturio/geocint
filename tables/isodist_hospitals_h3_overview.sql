insert into isodist_fire_stations_h3 (h3, resolution, man_distance)
select h3_to_parent(h3) as h3,
       max()
       :seq_res,


create table isodist_fire_stations_h3 as (
    select p.h3, 8 as resolution, (p.population * distance / 1000) as man_distance
    from kontur_population_h3 p
         cross join lateral (
        select (s.distance + ST_Distance(p.h3::geography, s.h3::geography)) as distance
        from isodist_fire_stations_h3_distinct s
        order by p.h3::geometry <-> s.geom
        limit 1
        ) d
    where p.resolution = 8
);
