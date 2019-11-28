copy (select json_agg(
                     jsonb_build_object('quotient', jsonb_build_array(numerator, denominator),
                                        'steps', jsonb_build_array(min, p25, p75, max)))
      from bivariate_axis
    ) to stdout;
