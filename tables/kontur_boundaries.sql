-- Prepare subdivided osm admin boundaries table with index for further queries
drop table if exists osm_admin_subdivided;
create table osm_admin_subdivided as
select
                osm_id,
                ST_Subdivide(ST_Transform(geom, 3857)) as geom
from osm_admin_boundaries;
create index on osm_admin_subdivided using gist(geom);


-- Sum population from h3 to osm admin boundaries
drop table if exists osm_admin_boundaries_in;
create table osm_admin_boundaries_in as
with sum_population as (
		select 
                                b.osm_id,
                                sum(h.population * 
                                        (case
                                                        when ST_Within(h.geom, b.geom)
                                                                        then 1
                                                        else ST_Area(ST_Intersection(h.geom, b.geom)) / ST_Area(h.geom)
                                        end) -- Calculate intersection area for each h3 cell and boundary polygon 
                                ) as population
		from osm_admin_subdivided b
		join kontur_population_h3 h
		                on ST_Intersects(h.geom, b.geom)
                		                and h.resolution = 8
                        	                and h.population > 0
		group by b.osm_id
)
select
                b.osm_id,
                b.osm_type,
                b.boundary,
                b.admin_level,
                b.name,
                b.tags,
                p.population,
                b.geom 
from osm_admin_boundaries b 
left join sum_population p using(osm_id);


-- Join OSM admin boundaries and HASC codes based on max IOU
drop table if exists kontur_boundaries;
create table kontur_boundaries as 
select 
                b.osm_id,
                b.osm_type,
                b.boundary,
                b.admin_level,
                g.gadm_level,
                b.name,
                g.hasc,
                g.iou osm_gadm_iou,
                b.tags,
                b.population,
                b.geom 
from osm_admin_boundaries_in b
left join lateral (
		select
				g.hasc,
                g.gadm_level,
                ST_Area(ST_Intersection(b.geom, g.geom))::numeric / ST_Area(ST_Union(b.geom, g.geom)) iou -- Calculate Intersection Over Union between OSM and GADM
		from gadm_boundaries g
		where ST_Intersects(g.geom, ST_PointOnSurface(b.geom))
				and ST_Intersects(b.geom, ST_PointOnSurface(g.geom))
		order by 3 desc
		limit 1
) g on true;


-- Drop temporary tables 
drop table if exists osm_admin_subdivided;
drop table if exists osm_admin_boundaries_in;