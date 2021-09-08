-- Prepare subdivided osm admin boundaries table with index for further queries
drop table if exists osm_admin_subdivided;
create table osm_admin_subdivided as
select
        osm_id,
        ST_Subdivide(ST_Transform(geom, 3857)) as geom
from osm_admin_boundaries;
create index on osm_admin_subdivided using gist(geom);


-- Sum population from h3 to osm admin boundaries (rounding to integers)
drop table if exists osm_admin_boundaries_in;
create table osm_admin_boundaries_in as
with sum_population as (
        select
                b.osm_id,
                round(sum(h.population *
                        (case
                                when ST_Within(h.geom, b.geom) then 1
                                else ST_Area(ST_Intersection(h.geom, b.geom)) / ST_Area(h.geom)
                        end) -- Calculate intersection area for each h3 cell and boundary polygon
                )) as population
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
create index on osm_admin_boundaries_in using gist(geom, ST_Area(geom));


-- Join OSM admin boundaries and HASC codes based on max IOU
drop table if exists kontur_boundaries;
create table kontur_boundaries as
with gadm_in as (
        select distinct on (g.geom)              -- (because of duplicates in GADM dataset)
                b.osm_id,
                g.id,
                g.hasc,
                g.gadm_level,
                b.iou
        from gadm_boundaries g
                left join lateral (
                        select
                                b.osm_id,
                                -- Calculate Intersection Over Union between OSM and GADM:
                                ST_Area(ST_Intersection(b.geom, g.geom))::numeric /
                                ST_Area(ST_Union(b.geom, g.geom)) as iou
                        from (
                                select b.osm_id, b.geom
                                from osm_admin_boundaries_in b
                                where ST_Area(b.geom) between 0.1 * ST_Area(g.geom) and 10 * ST_Area(g.geom)
                                        and (g.geom && b.geom)
                                order by abs(ST_Area(b.geom) - ST_Area(g.geom))
                                offset 0
                             ) b
                        where ST_Intersects(g.geom, b.geom)
                        order by 2 desc
                        limit 1
                        ) b on true
        order by g.geom, g.gadm_level
)
select distinct on ( b.osm_id)
        b.osm_id,
        g.id as gadm_id,
        b.osm_type,
        b.boundary,
        b.admin_level,
        b.name,
        g.hasc,
        g.gadm_level,
        g.iou as osm_gadm_iou,
        b.tags,
        b.population,
        b.geom
from
        osm_admin_boundaries_in b
left join gadm_in g using(osm_id)
order by b.osm_id, g.hasc is not null desc, g.iou desc;


-- Drop temporary tables
drop table if exists osm_admin_subdivided;
drop table if exists osm_admin_boundaries_in;

