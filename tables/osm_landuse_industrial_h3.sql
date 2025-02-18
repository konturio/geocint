drop table if exists osm_landuse_industrial_plain;
create table osm_landuse_industrial_plain as (
    select a.geom
    FROM osm_landuse_industrial a
    where not exists(
            select 1
            from osm_landuse_industrial b
            where ST_Intersects(a.geom, b.geom)
              and a.osm_id != b.osm_id)
    union all
    select (ST_Dump(ST_union(a.geom))).geom as geom
    from osm_landuse_industrial a,
         osm_landuse_industrial b
    where a.osm_id <> b.osm_id
      and ST_intersects(a.geom, b.geom)
);


drop table if exists osm_landuse_industrial_h3_in;
create table osm_landuse_industrial_h3_in as (
    select h3,
           st_setsrid(h3_cell_to_boundary_geometry(h3), 4326) as geom
    from (select distinct h3_polygon_to_cells(geom, 8) as h3
          from osm_landuse_industrial_plain
          union
          select distinct h3_grid_path_cells(
                                  h3_lat_lng_to_cell(st_startpoint(b.line_segment)::point, 8),
                                  h3_lat_lng_to_cell(st_endpoint(b.line_segment)::point, 8))
                from
                     (select (ST_DumpSegments(geom)).geom as line_segment from osm_landuse_industrial_plain) b
         ) a
);

create index on osm_landuse_industrial_h3_in using gist(geom);

drop table if exists osm_landuse_industrial_h3;

create table osm_landuse_industrial_h3 as
select h3,
       sum(industrial_area) as industrial_area,
       8::int               as resolution
from (select h.h3,
             ST_Area((ST_Intersection(h.geom, i.geom))::geography) / 1000000.0 as industrial_area
      from osm_landuse_industrial_h3_in h
               join osm_landuse_industrial_plain i on ST_Intersects(h.geom, i.geom)
     ) a
group by h3;

drop table if exists osm_landuse_industrial_h3_in;
drop table if exists osm_landuse_industrial_plain;
