-- possible problem with such method
-- for island country extent will show only the biggest island

drop table if exists hdx_boundaries_iso3_bigest_polygon;

create table hdx_boundaries_iso3_bigest_polygon as
with cnt_polygons as (select code, hasc_wiki, st_union(geom) as geom
    from hdx_boundaries as h,
        hdx_locations_with_wikicodes as hc
        where hasc_wiki = hc.hasc
    group by 1,2)
, dmp as (select code, (st_dump(geom)).geom
    from cnt_polygons)
, bigest_polygon as (select distinct on (code) code, geom
    from dmp
    order by code, st_area(geom) desc)
select code, replace(replace(replace(replace(st_extent(ST_QuantizeCoordinates(geom,1))::box2d::text,
    '(','='),')',''), 'BOX', 'bbox'),' ',',') as bbox
from bigest_polygon
group by 1;