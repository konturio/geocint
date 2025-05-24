-- relative elevation model
-- subtract interpolated water level from gebco elevation

drop table if exists relative_elevation_h3;
create table relative_elevation_h3 as (
    select g.h3,
           g.resolution,
           g.avg_elevation_gebco_2022 - w.water_elevation_m as relative_elevation_m
    from gebco_2022_h3 g
         join water_level_idw_h3 w using (h3)
);

create index on relative_elevation_h3 (h3);
