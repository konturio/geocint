copy (select
          jsonb_build_object(
                  'name', 'Kontur OpenStreetMap Coverage Map',
                  'description', 'This map shows relative distribution of OpenStreetMap object ' ||
                                 'count and Population. Last updated ' ||
                                 (select meta -> 'data' -> 'timestamp' ->> 'last' from osm_meta) || '.',
                  'attribution', 'Map Object Density © OpenStreetMap contributors, https://www.openstreetmap.org/copyright. Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe.
Dataset: Schiavina, Marcello; Freire, Sergio; MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio; MacManus, Kytt; Pesaresi, Martino; Doxsey-Whitfield, Erin; Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016.
',
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
