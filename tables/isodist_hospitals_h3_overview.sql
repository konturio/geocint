insert into isodist_hospitals_h3 (h3, resolution, distance, man_distance)
select p.h3,
       p.resolution,
       a.max_distance,
       (p.population * a.max_distance / 1000)
from (select h3_to_parent(h3) as h3,
             max(distance)    as max_distance
      from isodist_hospitals_h3
      where resolution = :seq_res
      group by 1) a
         join kontur_population_h3 p
              on a.h3 = p.h3
                  and p.resolution = :seq_res - 1
;