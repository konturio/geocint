drop table if exists osm_emergency_facilities;
create table osm_emergency_facilities as (
    select  distinct on (osm_id, osm_type) osm_type,
            osm_id,
            geog::geometry  as geom,
            'defibrillator' as type,
            tags ->> 'name' as name,
            tags
    from osm o
    where tags ->> 'emergency' = 'defibrillator'
    order by 1,2,_ST_SortableHash(geog::geometry)
);