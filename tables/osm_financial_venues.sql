drop table if exists osm_financial_venues;
create table osm_financial_venues as (
    select  osm_type,
            osm_id,
            geog::geometry as geom,
            case
                when tags ->> 'amenity' = 'bank'
                    then 'bank'
                when tags ->> 'amenity' = 'atm'
                    then 'osm_art_venues'
            end as type,
            tags ->> 'name' as name,
            tags
    from osm o
    where tags ->> 'amenity' in ('bank','atm')
    order by _ST_SortableHash(geog::geometry)
);