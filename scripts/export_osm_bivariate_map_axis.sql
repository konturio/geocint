copy (select json_agg(
                     jsonb_build_object('quotient', jsonb_build_array(division, divisor),
                                        'boundaries', jsonb_build_array(min, p25, p75, max)))
      from bivariate_axis
    ) to stdout;


-- copy (select jsonb_build_array(
--                      jsonb_build_object(
--                              'sideA', 'count',
--                              'sideB', 'area_km2',
--                              'min', (select count_min from osm_quality_bivariate_grid_h3_meta),
--                              'max', (select count_max from osm_quality_bivariate_grid_h3_meta),
--                              'p25', (select count_25 from osm_quality_bivariate_grid_h3_meta),
--                              'p75', (select count_75 from osm_quality_bivariate_grid_h3_meta)
--                          ),
--                      jsonb_build_object(
--                              'sideA', 'population',
--                              'sideB', 'area_km2',
--                              'min', (select population_min from osm_quality_bivariate_grid_h3_meta),
--                              'max', (select population_max from osm_quality_bivariate_grid_h3_meta),
--                              'p25', (select population_25 from osm_quality_bivariate_grid_h3_meta),
--                              'p75', (select population_75 from osm_quality_bivariate_grid_h3_meta)
--                          ),
--                      jsonb_build_object(
--                              'sideA', 'building_count',
--                              'sideB', 'area_km2',
--                              'min', (select building_count_min from osm_quality_bivariate_grid_h3_meta),
--                              'max', (select building_count_max from osm_quality_bivariate_grid_h3_meta),
--                              'p25', (select building_count_25 from osm_quality_bivariate_grid_h3_meta),
--                              'p75', (select building_count_75 from osm_quality_bivariate_grid_h3_meta)
--                          )
--                  )
--     ) to stdout;
