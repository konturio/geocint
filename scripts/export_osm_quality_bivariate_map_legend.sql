copy (select
          jsonb_build_object(
                  'name', 'Kontur OpenStreetMap Coverage Map',
                  'description', 'This map shows relative distribution of OpenStreetMap object ' ||
                                 'count and Population. Last updated ' ||
                                 (select meta -> 'data' -> 'timestamp' ->> 'last' from osm_meta) || '.',
                  'attribution', 'Map Object Density © OpenStreetMap contributors, https://www.openstreetmap.org/copyright.
European Commission, Joint Research Centre (JRC); Columbia University, Center for International Earth Science Information Network - CIESIN (2015): GHS population grid, derived from GPW4, multitemporal (1975, 1990, 2000, 2015). European Commission, Joint Research Centre (JRC) [Dataset] PID: http://data.europa.eu/89h/jrc-ghsl-ghs_pop_gpw4_globe_r2015a',
                  'max_zoom', 7,
                  'min_zoom', 0,
                  'tile_size', 512,
                  'tile_type', 'vector',
                  'view_type', 'fill',
                  'source_layer', 'bivariate_class',
                  'overlay', true,
                  'legend', jsonb_build_object(
                          'type', 'bivariate',
                          'colors',
                          jsonb_build_array(
                                  jsonb_build_object('id', 'A1', 'color', '#e8e89d', 'description',
                                                     'Almost nobody lives here. There isn’t much map.'),
                                  jsonb_build_object('id', 'A2', 'color', '#e47f81', 'description',
                                                     'Some people live here, but not much map.'),
                                  jsonb_build_object('id', 'A3', 'color', '#e41a1c', 'description',
                                                     'Many people live here, almost nothing mapped!'),
                                  jsonb_build_object('id', 'B1', 'color', '#ade4bf', 'description',
                                                     'Almost nobody lives here. There is some map.'),
                                  jsonb_build_object('id', 'B2', 'color', '#adad6c', 'description',
                                                     'Some people live here and have some map.'),
                                  jsonb_build_object('id', 'B3', 'color', '#8c6262', 'description',
                                                     'Many people live here, but not much map!'),
                                  jsonb_build_object('id', 'C1', 'color', '#5ac87f', 'description',
                                                     'Almost nobody lives here. Detailed map.'),
                                  jsonb_build_object('id', 'C2', 'color', '#4daf4a', 'description',
                                                     'Some people live here. Detailed map.'),
                                  jsonb_build_object('id', 'C3', 'color', '#53986a', 'description',
                                                     'Many people live here. Detailed map.')
                              ),
                          'xAxisName', 'Population (ppl/km²)',
                          'xScale', jsonb_build_array(
                                      (select population_12 from osm_quality_bivariate_grid_1000_meta),
                                      (select population_23 from osm_quality_bivariate_grid_1000_meta),
                                      (select population_max from osm_quality_bivariate_grid_1000_meta)
                              ),
                          'yAxisName', 'Map objects (n/km²)',
                          'yScale', jsonb_build_array(
                                      (select count_ab from osm_quality_bivariate_grid_1000_meta),
                                      (select count_bc from osm_quality_bivariate_grid_1000_meta),
                                      (select count_max from osm_quality_bivariate_grid_1000_meta)
                              )
                      )
              )) to stdout;
