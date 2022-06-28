insert into isodist_fire_stations_h3 (h3, resolution, distance, man_distance)
select h3_to_parent(i.h3) as h3,
       :seq_res - 1       as resolution,
       max(i.distance)    as distance,
       --(sum(distance * p.population)) / sum(population) as man_distance
       (sum(i.man_distance * p.population)) / sum(p.population) as man_distance
from isodist_fire_stations_h3 i
         join kontur_population_h3 p
              on i.h3 = p.h3
where i.resolution = :seq_res
  and p.resolution = :seq_res
group by 1;

