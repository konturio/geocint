drop table if exists osm_landuse_industrial;
create table osm_landuse_industrial as (
    select osm_id,
           osm_type,
           tags ->> 'landuse'     as landuse,
           coalesce(tags ->> 'industrial', tags ->> 'man_made')  as industrial,
           tags,
           geog::geometry         as geom
    from osm
    where (tags ? 'industrial' or tags ->> 'landuse' in ('harbour', 'industrial') or tags ->> 'man_made' = 'works')
      and ST_Dimension(geog::geometry) = 2
    order by _ST_SortableHash(geog::geometry)
);

create index on osm_landuse_industrial using brin(geom);