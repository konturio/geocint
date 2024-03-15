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
        from kontur_boundaries_v4 k2
        left join osm_admin_boundaries k using (osm_id)
        where k.osm_id is null
     ) ,
    -- Here, we check whether the missing boundary polygon still exists in OSM table, but have another value in boundary key
    -- In most cases that means valid change to e.g. boundary = historic or boundary = unofficial. So we filter out those cases:
    missing_boundaries_filtered as (
        select b.*
        from missing_boundaries b
        left join osm o
            on b.osm_id = o.osm_id
                and o.tags ? 'boundary'
                and ST_Dimension(o.geog::geometry) = 2
        where o.osm_id is null
    )
    select row_number() over ()                                                                             as id,

           -- Generate link to object properties on osm.org:
           'href_[' || b.osm_id || '](https://www.openstreetmap.org/' || osm_type || '/' || osm_id || ')'   as "OSM id",

           -- Generate link for JOSM remote desktop:
           'hrefIcon_[' || b.name ||
           '](http://127.0.0.1:8111/load_object?new_layer=false&objects=' ||
           left(b.osm_type, 1) || osm_id || '&relation_members=true)'                                       as "Name",

           b.admin_level                                                                                    as "Admin level",
           c.name                                                                                           as "Country"
    from missing_boundaries b
    left join country_boundaries_subdivided_in c
        on ST_Intersects(ST_PointOnSurface(b.geom), c.geom)
);