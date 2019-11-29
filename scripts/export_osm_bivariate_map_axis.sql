copy (select jsonb_build_object('axis', json_agg(
        jsonb_build_object('quotient', jsonb_build_array(numerator, denominator),
                           'steps', jsonb_build_array(min, p25, p75, max))),
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
        }'::json)
      from bivariate_axis
    ) to stdout;