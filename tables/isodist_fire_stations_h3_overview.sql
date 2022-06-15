insert into isodist_fire_stations_h3 (h3, resolution, man_distance)
select h3_to_parent(i.h3) as h3,
       max(i.distance) as distance,
       (max(i.distance) * p.population / 1000) as man_distance
       from isodist_fire_stations_h3 i
cross join lateral (
        select population
        from kontur_population_h3 p
    where p.resolution = (:seq_res - 1)
    and p.h3 = h3_to_parent(i.h3)
        ) d
       where i.resolution = :seq_res;






insert into test_isodist_fire_stations_h3 (h3, resolution, man_distance)
select h3_to_parent(i.h3) as h3,
       max(i.distance) as distance,
       (max(i.distance) * d.population / 1000) as man_distance
       from test_isodist_fire_stations_h3 i
cross join lateral (
        select population
        from kontur_population_h3 p
    where p.resolution = 7
    and p.h3 = h3_to_parent(i.h3)
        ) d
       where i.resolution = 8;