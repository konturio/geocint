-- Compare GADM and OpenStreetMap boundaries
drop table if exists osm_gadm_comparison;
create table osm_gadm_comparison as
with gadm_in as (
        -- Join GADM with itself to get parents for every boundary
        -- Join kontur_boundaries to get corresponding osm features ids
        select
                g.id,
                k.osm_id,
                k.admin_level::int,
                coalesce(k.tags ->> 'name:en', k.tags ->> 'int_name', k.name) as osm_name,   -- We want english names first in the reports
                g.name gadm_name,
                case
                        when g.gadm_level = 0 then g.gid_0
                        when g.gadm_level = 1 then g.gid_1
                        when g.gadm_level = 2 then g.gid_2
                        when g.gadm_level = 3 then g.gid_3
                end gid,
                case
                        when g.gadm_level = 1 then g.gid_0
                        when g.gadm_level = 2 then g.gid_1
                        when g.gadm_level = 3 then g.gid_2
                end parent_gid,
                g.gadm_level
        from gadm_boundaries g
        left join kontur_boundaries k
                on g.id = k.gadm_id
                        and k.admin_level ~ '^\d{1,2}$'
)
-- Count subregions for every boundary on levels 0-2 of GADM dataset
-- Count corresponding OpenStreetMap features
select
        g1.osm_id                                                   as "OSM ID",
        g1.admin_level                                              as "Admin level",
        g1.osm_name                                                 as "OSM name",
        g1.gadm_name                                                as "GADM name",
        (count(g2.id) filter(where g2.osm_id is not null))::text
            || ' / ' || count(g2.id)::text                          as "OSM / GADM count"
from gadm_in g1
left join gadm_in g2
        on g1.gid = g2.parent_gid
where g1.gadm_level < 3
        and (g1.gadm_name is not null and g1.osm_id is not null)
group by g1.osm_id, g1.admin_level, g1.osm_name, g1.gadm_name
having count(g2.id) filter(where g2.osm_id is not null) < count(g2.id)
order by g1.admin_level, g1.gadm_name;


-- Update timestamp in reports table (for further export to reports API JSON):
update osm_reports_list
set last_updated = (select meta->'data'->'timestamp'->>'last' as updated from osm_meta)
where id = 'osm_gadm_comparison';