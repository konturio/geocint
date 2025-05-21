drop table if exists osm_financial_venues;
create table osm_financial_venues as (
    select  distinct on (osm_id, osm_type) osm_type,
            osm_id,
            geog::geometry as geom,
            case
                when tags ->> 'amenity' = 'bank'
                    then 'bank'
                when tags ->> 'amenity' = 'atm'
                    then 'atm'
            end as type,
            tags ->> 'name' as name,
            tags
    from osm o
    -- index-friendly tag compare
    where (tags ? 'amenity' and tags->>'amenity' in ('bank','atm'))
    order by 1,2,_ST_SortableHash(geog::geometry)
);