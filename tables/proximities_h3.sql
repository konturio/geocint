drop table if exists proximities_h3;

create table proximities_h3 as
    (select a.h3,
            a.resolution,
            a.powerlines_proximity_m,
            b.populated_areas_proximity_m,
            c.power_substations_proximity_m
     from land_polygons_h3_r8 land
              inner join
          powerlines_proximity_h3 a on land.h3 = a.h3
              inner join populated_areas_proximity_h3 b on land.h3 = b.h3
              inner join power_substations_proximity_h3 c on land.h3 = c.h3);

drop table if exists populated_areas_proximity_h3_r8;
drop table if exists powerlines_proximity_h3_r8;
drop table if exists power_substations_proximity_h3_r8;