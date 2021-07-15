drop table if exists osm_landuse_industrial_h3_in;
create table osm_landuse_industrial_h3_in as (
    select h3,
           h3_to_geo_boundary_geography(h3) as geom
    from (select distinct h3_polyfill(geom, 8) as h3
          from osm_landuse_industrial
          union
          select distinct h3_line(
                                  h3_geo_to_h3(st_startpoint(b.line_segment), 8),
                                  h3_geo_to_h3(st_endpoint(b.line_segment), 8))
                from
                     (select (ST_DumpSegments(geom)).geom as line_segment from osm_landuse_industrial) b
         ) a
);

create index on osm_landuse_industrial_h3_in using gist(geom);

drop table if exists osm_landuse_industrial_h3;

create table osm_landuse_industrial_h3 as
select h3,
       sum(industrial_area) as industrial_area,
       8::int               as resolution
from (select h.h3,
             ST_Area((ST_Intersection(i.geom, h.geom))::geography) / 1000000.0 as industrial_area
      from osm_landuse_industrial_h3_in h
               join osm_landuse_industrial i on ST_Intersects(h.geom, i.geom)
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