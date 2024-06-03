drop table if exists meta_forest_canopy_height_h3;
create table meta_forest_canopy_height_h3 as (
       select h3         as h3,
              8          as resolution,
              avg(p.val) as avg_forest_canopy_height,
              max(p.val) as max_forest_canopy_height
       from meta_forest_canopy_height c,
            ST_PixelAsPolygons(ST_Transform(rast,4326)) p,
            h3_lat_lng_to_cell(p.geom::box::point, 8) as h3
       where p.val not in (0)
       group by 1
);