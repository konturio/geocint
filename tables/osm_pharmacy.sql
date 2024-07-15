drop table if exists osm_pharmacy_in;
create table osm_pharmacy_in as (
    select  osm_type,
            osm_id,
            geog::geometry as geom,
            tags ->> 'operator' as operator,
            tags ->> 'opening_hours' as opening_hours,
            tags
    from osm o
    where tags @> '{"amenity":"pharmacy"}' 
          or tags ->> 'tourism' in ('guest_house','hotel','hostel','motel')    
);

drop table if exists osm_pharmacy;
create table osm_pharmacy as (
    select  osm_type,
            osm_id,
            geom,
            operator,
            opening_hours,
            tags
    from osm_pharmacy_in
    order by _ST_SortableHash(geom)
);

drop table if exists osm_pharmacy_in;