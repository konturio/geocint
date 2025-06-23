-- interpolate water surface elevation using IDW from inland water bodies
-- base data: water_bodies_h3 joined with gebco_h3
-- result: average water elevation per cell in meters

drop table if exists temp_gebco_with_geom;
create table temp_gebco_with_geom as (
	select h3, 
	       avg_elevation_gebco,
	       h3_cell_to_boundary_geometry(i.h3) as geom
	from gebco_h3
);

create index on temp_gebco_with_geom using gist(geom);
create index on temp_gebco_with_geom using btree(h3);

-- table with water level known values
drop table if exists water_bodies_elevation_h3;
create table water_bodies_elevation_h3 as (
    select w.h3,
           w.geom,
           g.avg_elevation_gebco as water_elevation
    from water_bodies_h3 w
         join temp_gebco_with_geom g using (h3)
);
create index on water_bodies_elevation_h3 using gist(geom);

-- interpolate for all gebco cells
drop table if exists water_level_idw_h3;
create table water_level_idw_h3 as
with nearest as (
    select g.h3,
           n.water_elevation,
           st_distance(g.geom::geography, n.geom::geography) as dist
    from temp_gebco_with_geom g
         cross join lateral (
             select water_elevation, geom
             from water_bodies_elevation_h3
             order by geom <-> g.geom
             limit 4
         ) n
)
select h3,
       8 as resolution,
       sum(water_elevation / dist) / sum(1 / dist) as water_elevation
from nearest
group by h3;

create index on water_level_idw_h3 (h3);

drop table if exists water_bodies_elevation_h3;

call generate_overviews('water_bodies_elevation_h3', '{water_elevation}'::text[], '{avg}'::text[], 8);
