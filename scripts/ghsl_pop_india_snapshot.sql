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
, h3_r8 as (select (hs).h3, ((hs).stats).sum as population
    from cnt_clip, 
        lateral h3_raster_summary_centroids(rast, 8) as hs)
select h3, floor(sum(floor(population))) as population, 
    h3_cell_to_boundary_geometry(h3) as geom
from h3_r8
where floor(population) > 0
group by h3;