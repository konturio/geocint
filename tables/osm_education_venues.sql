drop table if exists osm_education_venues;
create table osm_education_venues as (
    select  osm_type,
            osm_id,
            geog::geometry as geom,
            case
                when tags ->> 'amenity' = 'kindergarten'
                     or tags ->> 'building' = 'kindergarten'
                    then 'kindergarten'
                when tags ->> 'amenity' = 'school'
                     or tags ->> 'building' = 'school'
                     or tags ->> 'military' = 'school'
                    then 'school'
                when tags ->> 'amenity' in ('college','university')
                     or tags ->> 'building' in ('college','university')
                    then 'university'
            end as type,
            tags ->> 'name' as name,
            tags
    from osm o
    where tags ->> 'amenity' in ('kindergarten','school','college','university')
          or tags ->> 'building' in ('kindergarten','school','college','university')
          or tags ->> 'military' = 'school'
    order by _ST_SortableHash(geog::geometry)
);