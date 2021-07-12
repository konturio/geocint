drop table if exists osm_landuse_industrial_h3_in;
create table osm_landuse_industrial_h3_in as
    (select distinct
            h3_polyfill(geog, 8)     as h3,
            h3_to_geo_boundary_geography(h3_polyfill(geog, 8)) as h3_geog
     from osm_landuse_industrial);
--TODO: add h3 that intersects st_boundary(geog)

create index on osm_landuse_industrial_h3_in using gist(h3_geog);

drop table if exists osm_landuse_industrial_h3;

create table osm_landuse_industrial_h3 as
select h3,
       sum(industrial_area) as industrial_area,
       8::int               as resolution
from (select h.h3,
             ST_Area(ST_Intersection(i.geog, h.h3_geog)) / 1000000.0 as industrial_area
      from osm_landuse_industrial_h3_in h
               join osm_landuse_industrial i on ST_Intersects(h.h3_geog, i.geog)
     ) a
group by h3;

drop table if exists osm_landuse_industrial_h3_in;

-- generate overviews
do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into osm_landuse_industrial_h3 (h3, industrial_area, resolution)
                select h3_to_parent(h3) as h3, sum(industrial_area), (res - 1) as resolution
                from osm_landuse_industrial_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;