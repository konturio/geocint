drop table if exists :tab_result;

-- 'osm_id = 304716' for India
-- takes ~15 min to create table
-- 'rast &&' to force using index
create table :tab_result as
with cnt_clip as (select rid, rast
    from :tab_name as r,
        public.kontur_boundaries as b
    where rast && st_transform(geom, 54009) and
        st_intersects(rast, st_transform(geom, 54009))
        and b.osm_id = 304716)
, h3_r8 as (select h3, 8 as resolution, sum(sum) as population
    from (select (h3_raster_sum_to_h3(rast, 8)).* 
        from cnt_clip) as z
    group by 1
)
select resolution, CEIL(population) as population, 
    h3_cell_to_boundary_geometry(h3) as geom
from h3_r8;