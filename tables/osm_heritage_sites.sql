drop table if exists osm_heritage_sites;
create table osm_heritage_sites as (
    select distinct on (osm_id, osm_type)
        osm_type,
        osm_id,
        parse_integer(tags ->> 'heritage')  as heritage_admin_level,
        tags ->> 'heritage:operator'        as heritage_operator,
        tags,
        ST_Normalize(geog::geometry)        as geom
    from osm o
    where tags ? 'heritage'
          and tags ->> 'heritage' != 'no'
    order by 1, 2, ST_Dimension(ST_Normalize(geog::geometry)) desc
);
