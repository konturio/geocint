drop table if exists osm_pharmacy;
create table osm_pharmacy as (
    select  distinct on (osm_id, osm_type) osm_type,
            osm_id,
            geog::geometry as geom,
            tags ->> 'operator' as operator,
            tags ->> 'opening_hours' as opening_hours,
            tags
    from osm o
    where tags @> '{"amenity":"pharmacy"}' 
          or tags @> '{"shop":"chemist"}'
          or tags @> '{"healthcare":"pharmacy"}'
    order by 1,2,_ST_SortableHash(geog::geometry)
);
