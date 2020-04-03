drop table if exists osm_buildings;
drop table if exists osm_buildings_minsk;

create table osm_buildings as (
    select osm_type,
           osm_id,
           tags ->> 'building'                as building,
           tags ->> 'addr:street'             as street,
           tags ->> 'addr:housenumber'        as hno,
           tags ->> 'building:levels'         as levels,
           tags ->> 'height'                  as height,
           tags ->> 'building:use'            as use,
           tags ->> 'name'                    as name,
           ST_Transform(geog::geometry, 3857) as geom
    from osm
    where tags ? 'building'
);
