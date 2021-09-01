drop table if exists osm_buildings;
create table osm_buildings as (
    select osm_type,
           osm_id,
           tags ->> 'building' as building,
           tags ->> 'addr:street' as street,
           tags ->> 'addr:housenumber' as hno,
           parse_integer(tags ->> 'building:levels') as levels,
           parse_float(tags ->> 'height') as height,
           coalesce(tags ->> 'building:use',
                    case
                        when tags ->> 'building' in
                             ('apartments', 'cathedral', 'chapel', 'church', 'civic', 'clinic',
                              'college', 'commercial',
                              'construction', 'dormitory', 'fire_station', 'garages',
                              'government', 'greenhouse', 'hospital',
                              'hotel', 'house', 'kindergarten', 'kiosk', 'office', 'parking',
                              'prison', 'public', 'residential',
                              'retail', 'school', 'service', 'sports_centre', 'sports_hall',
                              'stadium', 'train_station',
                              'transportation', 'university'
                             )
                            then tags ->> 'building'
                        when tags ->> 'building' in ('factory', 'warehouse', 'hangar', 'industrial')
                            then 'industrial'
                    end) as use,
           tags ->> 'name' as name,
           tags,
           geog::geometry as geom
    from osm o
    where tags ? 'building'
      and not (tags ->> 'building') = 'no'
    order by _ST_SortableHash(geog::geometry)
);

alter table osm_buildings set (parallel_workers=32); -- critical way

create index on osm_buildings using brin (geom); -- order by _ST_SortableHash