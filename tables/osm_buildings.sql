drop table if exists osm_buildings;

create table osm_buildings as (
    select osm_type,
           osm_id,
           tags ->> 'building'         as building,
           tags ->> 'addr:street'      as street,
           tags ->> 'addr:housenumber' as hno,
           tags ->> 'building:levels'  as levels,
           tags ->> 'height'           as height,
           tags ->> 'building:use'     as use,
           tags ->> 'name'             as "name",
           tags,
           geog::geometry              as geom
    from osm o
    where tags ? 'building'
      and tags != '{"building":"no"}'
);
