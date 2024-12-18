drop table if exists osm_heritage_sites;
create table osm_heritage_sites as (
    select distinct on (osm_id, osm_type)
        osm_type,
        osm_id,
        case
            when tags ->> 'heritage' = 'UNESCO' then 1
            when tags ->> 'heritage' = 'federal' then 2
            when tags ->> 'heritage' = 'regional' then 4
            when tags ->> 'heritage' ~ '^\d+(;\d+)+$' then (
                select min(cast(value as integer))
                from regexp_split_to_table(tags ->> 'heritage', ';') as value
            )
            else parse_integer(tags ->> 'heritage')
        end                                                          as heritage_admin_level,
        tags ->> 'heritage:operator'                                 as heritage_operator,
        tags,
        ST_Transform(ST_Normalize(geog::geometry),3857)              as geom
    from osm o
    where tags ? 'heritage'
          and tags ->> 'heritage' != 'no'
    order by 1, 2, ST_Dimension(ST_Normalize(geog::geometry)) desc
);

create index on osm_heritage_sites using gist(geom);