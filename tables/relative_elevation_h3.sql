-- relative elevation model
-- subtract interpolated water level from gebco elevation

drop table if exists relative_elevation_h3;
create table relative_elevation_h3 as (
    select g.h3,
           g.resolution,
           g.avg_elevation_gebco - w.water_elevation as relative_elevation
    from gebco_h3 g
         join water_level_idw_h3 w using (h3)
);

create index on relative_elevation_h3 (h3);
