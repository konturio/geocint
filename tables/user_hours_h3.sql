drop table if exists user_hours_h3;

create table user_hours_h3 as (
select h3,
       sum(uc.hours) FILTER (
           WHERE exists(
                   select
                   from osm_local_active_users au
                   where au.osm_user = uc.osm_user
                     and ST_Distance(
                                 geog,
                                 uc.h3::geography
                             ) <= (
                             50000 + h3_get_hexagon_edge_length_avg(uc.resolution)
                             )
               )
           )         as local_hours,
       sum(uc.hours) as total_hours
from osm_user_count_grid_h3 uc
group by h3
);

create index on user_hours_h3(h3);
