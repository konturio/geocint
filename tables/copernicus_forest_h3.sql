drop table if exists copernicus_forest_h3_in;
create table copernicus_forest_h3_in as (
    select h3,
           8                                                               as resolution,
           evergreen_needle_leaved_forest / 1000000                        as evergreen_needle_leaved_forest,
           shrubs / 1000000                                                as shrubs,
           herbage / 1000000                                               as herbage,
           unknown_forest / 1000000                                        as unknown_forest,
           forest_area / 1000000                                           as forest_area,
           ST_Area(h3_cell_to_boundary_geography(h3)) / 1000000.0 as area_km2
    from (
             select p_h3                                                             as h3,
                    coalesce(sum(cell_area) filter (where p.val in (111, 121)), 0)   as evergreen_needle_leaved_forest,
                    coalesce(sum(cell_area) filter (where p.val = 20), 0)            as shrubs,
                    coalesce(sum(cell_area) filter (where p.val = 30), 0)            as herbage,
                    coalesce(sum(cell_area) filter (where p.val in (116, 126)), 0)   as unknown_forest,
                    coalesce(sum(cell_area) filter (where p.val not in (20, 30)), 0) as forest_area
             from copernicus_landcover_raster c,
                  ST_PixelAsPolygons(rast) p,
                  h3_lat_lng_to_cell(p.geom::box::point, 8) as p_h3,
                  ST_Area(p.geom::geography) as cell_area
             where p.val in (20, 30, 111, 113, 112, 114, 115, 116, 121, 123, 122, 124, 125, 126)
             group by 1
         ) x
);

-- p.val list based on Discrete classification coding
-- from Copernicus Global Land Service: https://zenodo.org/record/4723921#.YQmESVMzaDV


-- generate overviews
-- TODO: rewrite generated_overviews() procedure to receive expression to "method" parameter for column
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
                select h3_cell_to_parent(h3),
                       sum(forest_area),
                       sum(evergreen_needle_leaved_forest),
                       sum(shrubs),
                       sum(herbage),
                       sum(unknown_forest),
                       ST_Area(h3_cell_to_boundary_geography(h3_cell_to_parent(h3))) / 1000000.0,
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
