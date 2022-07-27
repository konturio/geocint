drop table if exists total_road_length_h3_temp;
drop table if exists total_road_length_h3;

-- create temporary table with calculating basic total_road_length
create table total_road_length_h3_temp as (select coalesce(fb.h3, osm.h3)                                           as h3,
                                                   coalesce(fb.resolution, osm.resolution)                           as resolution,
                                                   coalesce(fb.fb_roads_length, 0)                                   as fb_roads_length,
                                                   coalesce(osm.highway_length, 0)                                   as highway_length,
                                                   coalesce(fb.fb_roads_length, 0) + coalesce(osm.highway_length, 0) as total_road_length
                                            from facebook_roads_h3 fb
                                                     full outer join osm_road_segments_h3 osm
                                                                     on fb.h3 = osm.h3
                                            where (coalesce(fb.resolution, osm.resolution) = 8));

-- calculate regression coefficients
with regression as (select regr_slope(trl.total_road_length, pop.population)     as slope,
                           regr_intercept(trl.total_road_length, pop.population) as intercept

                    from total_road_length_h3_temp trl
                             inner join kontur_population_h3 pop
                                        on trl.h3 = pop.h3,
                         (select percentile_disc(0.1) within group (order by pop.population) pop_lower_threshold,
                                 percentile_disc(0.95) within group (order by pop.population) pop_upper_threshold
                          from kontur_population_h3 pop
                          where (pop.population > 0)
                            and (pop.resolution = 8)) as pop_thr,

                         (select percentile_disc(0.01) within group (order by trl.total_road_length) road_lower_threshold,
                                 percentile_disc(0.99) within group (order by trl.total_road_length) road_upper_threshold
                          from total_road_length_h3_temp trl
                          where (trl.total_road_length > 0)
                            and (trl.total_road_length > trl.highway_length)) as road_thr

                    where (trl.total_road_length > trl.highway_length)
                      and (pop.population > pop_thr.pop_lower_threshold)
                      and (pop.population < pop_thr.pop_upper_threshold)
                      and (trl.total_road_length > road_thr.road_lower_threshold)
                      and (trl.total_road_length < road_thr.road_upper_threshold))
-- calculate new total_road_length with regression coefficients if it's bigger than basic one
select trl.h3                                          as h3,
       trl.resolution                                  as resolution,
       case
           when trl.total_road_length > trl.highway_length then trl.total_road_length
           else GREATEST(trl.total_road_length, coalesce(pop.population * regression.slope +
                                                          regression.intercept,
                                                          0))
       end                                             as total_road_length
into total_road_length_h3
from regression,
     total_road_length_h3_temp trl
         left outer join kontur_population_h3 pop on trl.h3 = pop.h3;

-- drop temporary table
drop table if exists total_road_length_h3_temp;