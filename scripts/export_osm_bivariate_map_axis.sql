copy (select jsonb_build_object('axis', ba.axis,
                                'translations', '{
          "count": "Count",
          "building_count": "Building count",
          "highway_length": "Highway length",
          "amenity_count": "Amenity count",
          "osm_users": "OSM users",
          "osm_users_recent": "OSM users recent",
          "top_user": "Top user",
          "top_user_objects": "Top user objects",
          "population": "Population",
          "avg_ts": "Average time stamp",
          "max_ts": "Max time stamp",
          "p90_ts": "90 Percentile time stamp",
          "area_km2": "Area",
          "1": "1"
        }'::json,
                                'initAxis',
                                jsonb_build_object('x', jsonb_build_object('quotient',
                                                                           jsonb_build_array(x.numerator, x.denominator),
                                                                           'steps',
                                                                           jsonb_build_array(x.min, x.p25, x.p75, x.max)),
                                                   'y', jsonb_build_object('quotient',
                                                                           jsonb_build_array(y.numerator, y.denominator),
                                                                           'steps',
                                                                           jsonb_build_array(y.min, y.p25, y.p75, y.max))
                                    )
                 )
      from (select json_agg(jsonb_build_object('quotient', jsonb_build_array(numerator, denominator),
                                               'steps', jsonb_build_array(min, p25, p75, max))) as axis
            from bivariate_axis) ba,
           bivariate_axis x,
           bivariate_axis y
      where x.numerator = 'count'
        and x.denominator = 'area_km2'
        and y.numerator = 'population'
        and y.denominator = 'area_km2'
    ) to stdout;