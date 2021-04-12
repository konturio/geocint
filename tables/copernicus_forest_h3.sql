drop table if exists copernicus_forest_h3;
create table copernicus_forest_h3 as (
    select h3,
           8                as resolution,
           sum(forest_area) as forest_area
    from (
             select h3_geo_to_h3(geom, 8)                     as h3,
                    sum(cell_area) / 1000000.0 as forest_area
             from (
                      select ST_PointOnSurface(p.geom)      as geom,
                             ST_Area(geom::geography, true) as cell_area,
                             p.val                          as cells
                      from copernicus_landcover_raster,
                           ST_PixelAsPolygons(rast) p
                  ) z
             where cells in (111, 113, 112, 114, 115, 116, 121, 123, 122, 124, 125, 126)
             group by 1
         ) x
    group by 1
);

do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into copernicus_forest_h3 (h3, forest_area, resolution)
                select h3_to_parent(h3) as h3, sum(forest_area) as forest_cells, (res - 1) as resolution
                from copernicus_forest_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;
