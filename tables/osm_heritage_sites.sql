drop table if exists osm_heritage_sites;
create table osm_heritage_sites as (
    select distinct on (osm_id, osm_type)
        osm_type,
        osm_id,
        parse_integer(tags ->> 'heritage')              as heritage_admin_level,
        tags ->> 'heritage:operator'                    as heritage_operator,
        tags,
        ST_Transform(ST_Normalize(geog::geometry),3857) as geom
    from osm o
    where tags ? 'heritage'
          and tags ->> 'heritage' != 'no'
    order by 1, 2, ST_Dimension(ST_Normalize(geog::geometry)) desc
);

create index on osm_heritage_sites using gist(geom);