-- Subdivided country boundaries
drop table if exists country_boundaries_subdivided_in;
create table country_boundaries_subdivided_in as
select coalesce(tags ->> 'name:en', tags ->> 'int_name', name) as name,
       ST_Subdivide(geom)                                as geom
from osm_admin_boundaries where admin_level = '2';
create index on country_boundaries_subdivided_in using gist(geom);


drop table if exists osm_missing_boundaries_report;
create table osm_missing_boundaries_report as (
    with missing_boundaries as (
        select k2.*
        from kontur_boundaries_v2 k2
        left join osm_admin_boundaries k using (osm_id)
        where k.osm_id is null
    )
    select row_number() over ()                                                                             as id,

           -- Generate link to object properties on osm.org:
           'href_[' || b.osm_id || '](https://www.openstreetmap.org/' || osm_type || '/' || osm_id || ')'   as "OSM id",

           -- Generate link for JOSM remote desktop:
           'hrefIcon_[' || b.name ||
           '](http://localhost:8111/load_object?new_layer=false&objects=' ||
           left(b.osm_type, 1) || osm_id || '&relation_members=true)'                                       as "Name",

           b.admin_level                                                                                    as "Admin level",
           c.name                                                                                           as "Country"
    from missing_boundaries b
    left join country_boundaries_subdivided_in c
        on ST_Intersects(ST_PointOnSurface(b.geom), c.geom)
);


-- Update timestamp in reports table (for further export to reports API JSON):
update osm_reports_list
set last_updated = (select meta->'data'->'timestamp'->>'last' as updated from osm_meta)
where id = 'osm_missing_boundaries_report';