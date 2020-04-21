drop table if exists osm_landuses;

create table osm_landuses as (
    select osm_id,
           osm_type,
           tags ->> 'landuse'   as landuse,
           tags ->> 'amenity'   as anemity,
           tags ->> 'leisure'   as leisure,
           tags ->> 'landcover' as landcover,
           tags ->> 'tourism'   as tourism,
           tags ->> 'natural'   as "natural",
           geog::geometry       as geom
    from osm
    where (tags ? 'landuse' or tags ? 'amenity' or tags ? 'landcover' or tags ? 'leisure' or tags ? 'tourism' or tags ? 'natural')
);