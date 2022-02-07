drop table if exists osm_admin_boundaries;
create table osm_admin_boundaries as (
    select osm_id,
           osm_type,
           tags ->> 'boundary'    as boundary,
           tags ->> 'admin_level' as admin_level,
           tags ->> 'name'        as "name",
           tags,
           geog::geometry         as geom
    from osm
    where (
            tags ? 'admin_level'
        and tags @>
            '{"boundary":"administrative"}'
        and ST_Dimension(geog::geometry) = 2
        and not (tags ->> 'name' is null and tags @> '{"admin_level":"2"}')
    )
       or tags @> '{"ISO3166-1":"PS"}' -- Special rule for Palestinian Territories - because of it's disputed status it often lacks admin_level key
);

create index on osm_admin_boundaries using gist(geom);

delete from osm_admin_boundaries a
using osm_admin_boundaries b
where a.osm_id > b.osm_id and ST_Equals(a.geom, b.geom);

