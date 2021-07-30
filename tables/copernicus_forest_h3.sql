drop table if exists copernicus_forest_h3_in;
create table copernicus_forest_h3_in as (
    select h3,
           8                                                               as resolution,
           evergreen_needle_leaved_forest / 1000000                        as evergreen_needle_leaved_forest,
           shrubs / 1000000                                                as shrubs,
           herbage / 1000000                                               as herbage,
           unknown_forest / 1000000                                        as unknown_forest,
           forest_area / 1000000                                           as forest_area,
           ST_Area(h3_to_geo_boundary_geometry(h3)::geography) / 1000000.0 as area_km2
    from (
             select h3_geo_to_h3(geom, 8)                              as h3,
                    sum(cell_area) filter (where cell in (111, 121))   as evergreen_needle_leaved_forest,
                    sum(cell_area) filter (where cell = 20)            as shrubs,
                    sum(cell_area) filter (where cell = 30)            as herbage,
                    sum(cell_area) filter (where cell in (116, 126))   as unknown_forest,
                    sum(cell_area) filter (where cell not in (20, 30)) as forest_area
             from (
                      select ST_PointOnSurface(p.geom) as geom,
                             ST_Area(geom::geography)  as cell_area,
                             p.val                     as cell
                      from copernicus_landcover_raster,
                           ST_PixelAsPolygons(rast) p
                      where p.val in (20, 30, 111, 113, 112, 114, 115, 116, 121, 123, 122, 124, 125, 126)
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
                insert into copernicus_forest_h3_in (h3, forest_area, evergreen_needle_leaved_forest, shrubs, herbage,
                                                     unknown_forest, area_km2, resolution)
                select h3_to_parent(h3),
                       sum(forest_area),
                       sum(evergreen_needle_leaved_forest),
                       sum(shrubs),
                       sum(herbage),
                       sum(unknown_forest),
                       ST_Area(h3_to_geo_boundary_geometry(h3_to_parent(h3))::geography) / 1000000.0,
                       -- we have complex method to insert in into table as str
                       (res - 1)
                from copernicus_forest_h3_in
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;

drop table if exists copernicus_forest_h3;
create table copernicus_forest_h3
(
    like copernicus_forest_h3_in
);

-- dither areas to not be bigger than 100% of hexagon's area for every resolution
do
$$
    declare
        row         record;
        col_jsonb   jsonb;
        carry_jsonb jsonb;
        cur_row     record;
        cur_out     float;
        res         integer;
        carry       int;
    begin
        res = 8;
        while res > 0
            loop
                carry = 0;
                for cur_row in (select * from copernicus_forest_h3_in where resolution = res order by h3)
                    loop
                        -- create jsonb '{"column": ["resolution", "herbage", "shrublands", "area_km2", "forest_area", "h3"]}'
                        select jsonb_build_object('column', jsonb_agg(key))
                        into col_jsonb
                        from (select distinct (json_each_text(row_to_json(test_copernicus_forest_h3))).key
                              from test_copernicus_forest_h3) f;
                        -- loop through array at "column" values
                        for row in (select jsonb_array_elements(col_jsonb -> 'column') column_name)
                            loop
                                -- calculate carry for every column
                                carry = carry + cur_row.column_name;
                                cur_out = least(carry, cur_row.area_km2);
                                carry = carry - cur_out;
                                -- put carry into carry_jsonb and cur_out into jsonb too to insert their values into insert below
                                if cur_out > 0 then
                                    insert into copernicus_forest_h3 (h3, resolution, forest_area, area_km2)
                                    values (cur_row.h3, cur_row.resolution, cur_out, cur_row.area_km2);
                                end if;
                            end loop;
                        raise notice 'unprocessed carry %', carry;
                        res = res - 1;
                    end loop;
            end loop;
    end;
$$;

drop table if exists copernicus_forest_h3_in;
