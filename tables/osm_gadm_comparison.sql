-- Preprocess GADM boundaries so that it have gid and parent_gid identifiers from GADM itself as well as osm_id from OpenStreetMap
drop table if exists gadm_in;
create table gadm_in as
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
                end gid,                                                                     -- Take the lower gid level available for the feature
                case
                        when g.gadm_level = 1 then g.gid_0
                        when g.gadm_level = 2 then g.gid_1
                        when g.gadm_level = 3 then g.gid_2
                end parent_gid,                                                              -- Take the lower + 1 gid level as parent gid
                g.gadm_level
        from gadm_boundaries g
        left join kontur_boundaries k
                on g.id = k.gadm_id
                        and k.admin_level ~ '^\d{1,2}$';                                     -- Check admin_level to be proper int value

-- Indexes to speed up next query
create index on gadm_in(gid);
create index on gadm_in(parent_gid);


-- Count subregions for every boundary on levels 0-2 of GADM and OpenStreetMap and check how they correspond with each other
-- Then prepare full list of boundaries with their sub boundaries for features not consistent in OpenStreetMap and GADM
drop table if exists osm_gadm_comparison;
create table osm_gadm_comparison as
with list as (                                        -- Compare aggregated children counts from OpenStreetMap and GADM
    select g1.gid,
           g1.admin_level
    from gadm_in g1
    left join gadm_in g2
            on g1.gid = g2.parent_gid
    where g1.gadm_level < 3
            and (g1.gadm_name is not null and g1.osm_id is not null)
    group by g1.osm_id, g1.admin_level, g1.osm_name, g1.gadm_name, g1.gid
    having count(g2.id) filter (where g2.osm_id is not null) < count(g2.id)
    order by g1.admin_level, g1.gadm_name
)
select  row_number() over(order by l.admin_level, l.gid, g.admin_level, g.gadm_name)  as id,
        g.admin_level                                                                 as "Admin level",
        case when l.gid = g.gid then g.gadm_name  else '   - ' || g.gadm_name end     as "GADM name",
        case when l.gid = g.gid then g.osm_name   else '   - ' || g.osm_name  end     as "OSM name",
        g.osm_id                                                                      as "OSM id"
from list l
left join gadm_in g
        on l.gid = g.gid
           or l.gid = g.parent_gid
order by l.admin_level, l.gid, g.admin_level, g.gadm_name;

-- Drop temporary tables
drop table if exists gadm_in;

-- Update timestamp in reports table (for further export to reports API JSON):
update osm_reports_list
set last_updated = (select meta->'data'->'timestamp'->>'last' as updated from osm_meta)
where id = 'osm_gadm_comparison';