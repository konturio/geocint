copy (select jsonb_build_object('axis', ba.axis,
                                'translations', jsonb_build_object('count', 'Count',
                                                                   'building_count', 'Building count',
                                                                   'highway_length', 'Highway length',
                                                                   'amenity_count', 'Amenity count',
                                                                   'osm_users', 'OSM users',
                                                                   'osm_users_recent', 'OSM users recent',
                                                                   'top_user', 'Top user',
                                                                   'top_user_objects', 'Top user objects',
                                                                   'population', 'Population',
                                                                   'avg_ts', 'Average time stamp',
                                                                   'max_ts', 'Max time stamp',
                                                                   'p90_ts', '90 Percentile time stamp',
                                                                   'area_km2', 'Area',
                                                                   '1', '1'
                                    ),
                                'meta', jsonb_build_object('name', 'Kontur OpenStreetMap Coverage Map',
                                                           'description',
                                                           'This map shows relative distribution of OpenStreetMap object ' ||
                                                           'count and Population. Last updated ' ||
                                                           (select meta -> 'data' -> 'timestamp' ->> 'last' from osm_meta) ||
                                                           '.',
                                                           'attribution', 'Map Object Density © OpenStreetMap contributors, https://www.openstreetmap.org/copyright. Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe.
Dataset: Schiavina, Marcello; Freire, Sergio; MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio; MacManus, Kytt; Pesaresi, Martino; Doxsey-Whitfield, Erin; Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016.
',
                                                           'max_zoom', 8,
                                                           'min_zoom', 0),
                                'initAxis',
                                jsonb_build_object('x', jsonb_build_object('quotient',
                                                                           jsonb_build_array(x.numerator, x.denominator),
                                                                           'steps',
                                                                           jsonb_build_array(x.min, x.p25, x.p75, x.max)),
                                                   'y', jsonb_build_object('quotient',
                                                                           jsonb_build_array(y.numerator, y.denominator),
                                                                           'steps',
                                                                           jsonb_build_array(y.min, y.p25, y.p75, y.max))
                                    ),
                                'overlay', ov.overlay
                 )
      from (select json_agg(jsonb_build_object('quotient', jsonb_build_array(numerator, denominator),
                                               'steps', jsonb_build_array(min, p25, p75, max))) as axis
            from bivariate_axis) ba,
           (select json_agg(json_build_object('name', name,
                                              'active', active,
                                              'x', json_build_array(x_numerator, x_denominator),
                                              'y', json_build_array(y_numerator, y_denominator))) as overlay
            from bivariate_overlays) ov,
           bivariate_axis x,
           bivariate_axis y
      where x.numerator = 'count'
        and x.denominator = 'area_km2'
        and y.numerator = 'population'
        and y.denominator = 'area_km2'
    ) to stdout;