copy (
    select
        jsonb_build_object('axis', ba.axis,
                           'translations', jsonb_build_object('count', 'Count',
                                                              'building_count', 'Building count',
                                                              'highway_length', 'Highway length',
                                                              'amenity_count', 'Amenity count',
                                                              'view_count', 'Map views',
                                                              'osm_users', 'OSM users',
                                                              'population', 'Population',
                                                              'avg_ts', 'Average time stamp',
                                                              'max_ts', 'Max time stamp',
                                                              'p90_ts', '90 Percentile time stamp',
                                                              'area_km2', 'Area',
                                                              'one', '1'
                               ),
                           'meta', jsonb_build_object('max_zoom', 8,
                                                      'min_zoom', 0),
                           'correlationRates', (
                               select
                                   jsonb_agg(jsonb_build_object(
                                                 'x', jsonb_build_object('label', x_num,
                                                                         'quotient',
                                                                         jsonb_build_array(x_num, x_den)),
                                                 'y', jsonb_build_object('label', y_num,
                                                                         'quotient',
                                                                         jsonb_build_array(y_num, y_den)),
                                                 'rate', correlation, -- TODO: remove after frontend
                                                 'correlation', correlation,
                                                 'quality', quality
                                                 )
                                             order by abs(correlation) * quality nulls last, abs(correlation) desc)
                               from
                                   bivariate_axis_correlation
                           ),
                           'initAxis',
                           jsonb_build_object('x', jsonb_build_object('label', x.label, 'quotient',
                                                                      jsonb_build_array(x.numerator, x.denominator),
                                                                      'steps',
                                                                      jsonb_build_array(
                                                                          jsonb_build_object('value', x.min, 'label', x.min_label),
                                                                          jsonb_build_object('value', x.p25, 'label', x.p25_label),
                                                                          jsonb_build_object('value', x.p75, 'label', x.p75_label),
                                                                          jsonb_build_object('value', x.max, 'label', x.max_label))),
                                              'y', jsonb_build_object('label', y.label, 'quotient',
                                                                      jsonb_build_array(y.numerator, y.denominator),
                                                                      'steps',
                                                                      jsonb_build_array(
                                                                          jsonb_build_object('value', y.min, 'label', y.min_label),
                                                                          jsonb_build_object('value', y.p25, 'label', y.p25_label),
                                                                          jsonb_build_object('value', y.p75, 'label', y.p75_label),
                                                                          jsonb_build_object('value', y.max, 'label', y.max_label)))
                               ),
                           'overlays', ov.overlay,
                           'copyrights', copyrights.copyrights
            )
    from
        ( select
              json_agg(
                  jsonb_build_object('label', label, 'quotient', jsonb_build_array(numerator, denominator), 'quality',
                                     quality,
                                     'steps', jsonb_build_array(
                                         jsonb_build_object('value', min, 'label', min_label),
                                         jsonb_build_object('value', p25, 'label', p25_label),
                                         jsonb_build_object('value', p75, 'label', p75_label),
                                         jsonb_build_object('value', max, 'label', max_label)))) as axis
          from
              bivariate_axis )                                                                      ba,
        ( select
              json_agg(jsonb_build_object('name', o.name, 'active', o.active, 'description', o.description,
                                          'colors', o.colors,
                                          'x', jsonb_build_object('label', ax.label, 'quotient',
                                                                  jsonb_build_array(ax.numerator, ax.denominator),
                                                                  'steps',
                                                                  jsonb_build_array(
                                                                      jsonb_build_object('value', ax.min, 'label', ax.min_label),
                                                                      jsonb_build_object('value', ax.p25, 'label', ax.p25_label),
                                                                      jsonb_build_object('value', ax.p75, 'label', ax.p75_label),
                                                                      jsonb_build_object('value', ax.max, 'label', ax.max_label))),
                                          'y', jsonb_build_object('label', ay.label, 'quotient',
                                                                  jsonb_build_array(ay.numerator, ay.denominator),
                                                                  'steps',
                                                                  jsonb_build_array(
                                                                      jsonb_build_object('value', ay.min, 'label', ay.min_label),
                                                                      jsonb_build_object('value', ay.p25, 'label', ay.p25_label),
                                                                      jsonb_build_object('value', ay.p75, 'label', ay.p75_label),
                                                                      jsonb_build_object('value', ay.max, 'label', ay.max_label))))
                       order by ord) as overlay
          from
              bivariate_axis     ax,
              bivariate_axis     ay,
              bivariate_overlays o
          where
                ax.denominator = o.x_denominator
            and ax.numerator = o.x_numerator
            and ay.denominator = o.y_denominator
            and ay.numerator = o.y_numerator )                                                      ov,
        bivariate_axis                                                                              x,
        bivariate_axis                                                                              y,
        ( select json_object_agg(param_id, copyrights) as copyrights from bivariate_copyrights ) as copyrights
    where
          x.numerator = 'count'
      and x.denominator = 'area_km2'
      and y.numerator = 'view_count'
      and y.denominator = 'area_km2'
    ) to stdout;
