insert into :table_name (h3, resolution, distance, man_distance)
select p.h3,
       p.resolution,
       (a.man_dist_sum / p.population) * 1000,
       a.man_dist_sum
from (select h3_cell_to_parent(h3)     as h3,
             sum(man_distance)    as man_dist_sum -- weighted average distance is simple sum of child man_distances related to parent population. And according to that average distance new man_distance is just sum of child man_distances
      from :table_name
      where resolution = :seq_res
      group by 1) a
         join kontur_population_h3 p
              on a.h3 = p.h3
                  and p.resolution = :seq_res - 1
;