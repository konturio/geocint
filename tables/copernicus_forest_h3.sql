drop table if exists copernicus_forest_h3_in;
create table copernicus_forest_h3_in as (
    select h3,
           8           as resolution,
           forest_area as forest_area,
           ST_Area(h3_to_geo_boundary_geometry(h3)::geography) / 1000000.0 as area_km2
    from (
             select h3_geo_to_h3(geom, 8)      as h3,
                    sum(cell_area) / 1000000.0 as forest_area
             from (
                      select ST_PointOnSurface(p.geom)      as geom,
                             ST_Area(geom::geography)       as cell_area,
                             p.val                          as cells
                      from copernicus_landcover_raster,
                           ST_PixelAsPolygons(rast) p
                      where p.val in (111, 113, 112, 114, 115, 116, 121, 123, 122, 124, 125, 126)
                  ) z
             group by 1
         ) x
);

-- generate overviews
do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into copernicus_forest_h3_in (h3, forest_area, area_km2, resolution)
                select 
                    h3_to_parent(h3), 
                    sum(forest_area),
                    ST_Area(h3_to_geo_boundary_geometry(h3_to_parent(h3))::geography) / 1000000.0, 
                    (res - 1)
                from copernicus_forest_h3_in
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;

drop table if exists copernicus_forest_h3;
create table copernicus_forest_h3 (like copernicus_forest_h3_in);

-- dither areas to not be bigger than 100% of hexagon's area for every resolution
do
$$
    declare
        cur_row record;
        carry   float;
        cur_out float;
        res     integer;
    begin
        res = 8;
        while res > 0
            loop
                carry = 0;
                for cur_row in (select * from copernicus_forest_h3_in where resolution = res order by h3)
                    loop
                        carry = carry + cur_row.forest_area;
                        cur_out = least(carry, cur_row.area_km2);
                        carry = carry - cur_out;
                        if cur_out > 0 then
                            insert into copernicus_forest_h3 (h3, resolution, forest_area, area_km2)
                            values (cur_row.h3, cur_row.resolution, cur_out, cur_row.area_km2);
                        end if;
                    end loop;
                raise notice 'unprocessed carry %', carry;
                res = res - 1;
            end loop;
    end;
$$;

drop table if exists copernicus_forest_h3_in;


