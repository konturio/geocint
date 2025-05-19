-- possible problem with such method
-- for island country extent will show only the biggest island

drop table if exists hdx_boundaries_iso3_bbox;

drop table if exists hdx_boundaries_iso3_bbox;
create table hdx_boundaries_iso3_bbox as
with cnt_polygons as (select  code,
                              hasc_wiki,
                              ST_Union(geom) as geom
                      from hdx_boundaries,
                           hdx_locations_with_wikicodes as hc
                      where hasc_wiki = hc.hasc
                      group by code, hasc_wiki)
select  code,
        replace(
            replace(
                replace(
                    replace(
                        (case 
                            when ST_Distance(ST_Centroid(ST_Envelope(geom)),
                                             ST_Centroid(geom::geography)::geometry) > 
                                 ST_Distance(ST_Centroid(ST_Envelope(ST_ShiftLongitude(geom))), 
                                             ST_Union(ST_Centroid(geom::geography)::geometry, 
                                                      ST_ShiftLongitude(ST_Centroid(geom::geography)::geometry)))                                             
                            then box2d(ST_ShiftLongitude(geom))
                            else box2d(geom)
                        end)::text,'(','='),
                    ')',''),
                'BOX', 'bbox'),
            ' ',',') as bbox
from cnt_polygons
group by 1,geom;
