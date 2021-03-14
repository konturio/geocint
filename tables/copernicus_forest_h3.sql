drop table if exists copernicus_forest_h3;
create table copernicus_forest_h3 as (
    select h3,
           8 as resolution,
           1::float as forest_cells
    from (
             select h3_geo_to_h3(ST_Transform(geom, 4326)::point, 8) as h3
             from (
                      select p.geom, p.val
                      from copernicus_landcover_raster,
                           ST_PixelAsCentroids(rast) p
                  ) z
             where val in (111, 113, 112, 114, 115, 116, 121, 123, 122, 124, 125, 126)
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
                insert into copernicus_forest_h3 (h3, forest_cells, resolution)
                select h3_to_parent(h3) as h3, sum(forest_cells) as forest_cells, (res - 1) as resolution
                from copernicus_forest_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;
