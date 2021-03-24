drop table if exists osm_landuse;
create table osm_landuse as (
    select osm_id,
           osm_type,
           tags ->> 'landuse'     as landuse,
           tags ->> 'amenity'     as amenity,
           tags ->> 'residential' as residential,
           tags ->> 'industrial'  as industrial,
           tags ->> 'leisure'     as leisure,
           tags ->> 'landcover'   as landcover,
           tags ->> 'tourism'     as tourism,
           tags ->> 'natural'     as "natural",
           tags,
           geog::geometry         as geom
    from osm
    where (tags ? 'landuse' or tags ? 'amenity' or tags ? 'landcover' or tags ? 'leisure' or tags ? 'tourism' or
           tags ? 'natural' or tags ? 'residential' or tags ? 'office' or tags ? 'industrial')
      and ST_Dimension(geog::geometry) = 2
    order by _ST_SortableHash(geog::geometry)
);

create index on osm_landuse using brin(geom);
