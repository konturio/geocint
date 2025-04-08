drop table if exists copernicus_landcover_h3_in;
create table copernicus_landcover_h3_in as (
    select h3,
           8                                                      as resolution,
           evergreen_needle_leaved_forest / 1000000               as evergreen_needle_leaved_forest,
           shrubs / 1000000                                       as shrubs,
           herbage / 1000000                                      as herbage,
           unknown_forest / 1000000                               as unknown_forest,
           forest_area / 1000000                                  as forest_area,
           cropland / 1000000                                     as cropland,
           wetland / 1000000                                      as wetland,
           moss_lichen / 1000000                                  as moss_lichen,
           bare_vegetation / 1000000                              as bare_vegetation,
           builtup / 1000000                                      as builtup,
           snow_ice / 1000000                                     as snow_ice,
           permanent_water / 1000000                              as permanent_water,
           ST_Area(h3_cell_to_boundary_geography(h3)) / 1000000.0 as area_km2
    from (
             select p_h3                                                           as h3,
                    coalesce(sum(cell_area) filter (where p.val in (111, 121)), 0) as evergreen_needle_leaved_forest,
                    coalesce(sum(cell_area) filter (where p.val = 20), 0)          as shrubs,
                    coalesce(sum(cell_area) filter (where p.val = 30), 0)          as herbage,
                    coalesce(sum(cell_area) filter (where p.val in (116, 126)), 0) as unknown_forest,
                    coalesce(sum(cell_area) filter (where p.val > 100), 0)         as forest_area,
                    coalesce(sum(cell_area) filter (where p.val = 40), 0)          as cropland,
                    coalesce(sum(cell_area) filter (where p.val = 90), 0)          as wetland,
                    coalesce(sum(cell_area) filter (where p.val = 100), 0)         as moss_lichen,
                    coalesce(sum(cell_area) filter (where p.val = 60), 0)          as bare_vegetation,
                    coalesce(sum(cell_area) filter (where p.val = 50), 0)          as builtup,
                    coalesce(sum(cell_area) filter (where p.val = 70), 0)          as snow_ice,
                    coalesce(sum(cell_area) filter (where p.val = 80), 0)          as permanent_water
             from copernicus_landcover_raster c,
                  ST_PixelAsPolygons(rast) p,
                  h3_lat_lng_to_cell(p.geom::box::point, 8) as p_h3,
                  ST_Area(p.geom::geography) as cell_area
             where p.val not in (0, 200)
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
                insert into copernicus_landcover_h3_in (h3, forest_area, evergreen_needle_leaved_forest, shrubs, herbage,
                                                     unknown_forest, cropland, wetland, moss_lichen, bare_vegetation, 
                                                     builtup, snow_ice, permanent_water, area_km2, resolution)
                select h3_cell_to_parent(h3),
                       sum(forest_area),
                       sum(evergreen_needle_leaved_forest),
                       sum(shrubs),
                       sum(herbage),
                       sum(unknown_forest),
                       sum(cropland),
                       sum(wetland),
                       sum(moss_lichen),
                       sum(bare_vegetation),
                       sum(builtup),
                       sum(snow_ice),
                       sum(permanent_water),
                       ST_Area(h3_cell_to_boundary_geography(h3_cell_to_parent(h3))) / 1000000.0,
                       (res - 1)
                from copernicus_landcover_h3_in
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;

call dither_area_to_not_bigger_than_100pc_of_hex_area('copernicus_landcover_h3_in', 'copernicus_landcover_h3', '{forest_area, evergreen_needle_leaved_forest, shrubs, herbage, unknown_forest, cropland, wetland, moss_lichen, bare_vegetation, builtup, snow_ice, permanent_water}'::text[], 8);

drop table if exists copernicus_landcover_h3_in;