-- interpolate water surface elevation using IDW from inland water bodies
-- base data: water_bodies_h3 joined with gebco_2022_h3
-- result: average water elevation per cell in meters

-- table with water level known values
drop table if exists water_bodies_elevation_h3;
create table water_bodies_elevation_h3 as (
    select w.h3,
           w.geom,
           g.avg_elevation_gebco_2022 as water_elevation_m
    from water_bodies_h3 w
         join gebco_2022_h3 g using (h3)
);
create index on water_bodies_elevation_h3 using gist(geom);

-- interpolate for all gebco cells

drop table if exists water_level_idw_h3;
create table water_level_idw_h3 as
with nearest as (
    select g.h3,
           n.water_elevation_m,
           st_distance(g.geom::geography, n.geom::geography) as dist
    from gebco_2022_h3 g
         cross join lateral (
             select water_elevation_m, geom
             from water_bodies_elevation_h3
             order by geom <-> g.geom
             limit 4
         ) n
)
select h3,
       8 as resolution,
       sum(water_elevation_m / dist) / sum(1 / dist) as water_elevation_m
from nearest
group by h3;

create index on water_level_idw_h3 (h3);

drop table if exists water_bodies_elevation_h3;
