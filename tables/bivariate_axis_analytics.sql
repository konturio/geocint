update bivariate_axis
set sum_value      = a.sum_value,
    sum_quality    = a.sum_quality,
    min_value      = a.min_value,
    min_quality    = a.min_quality,
    max_value      = a.max_value,
    max_quality    = a.max_quality,
    stddev_value   = a.stddev_value,
    stddev_quality = a.stddev_quality,
    median_value   = a.median_value,
    median_quality = a.median_quality,
    mean_value     = a.mean_value,
    mean_quality   = a.mean_quality
from (
         select avg(sum_m) filter (where r = 8)    as sum_value,
                case
                    when (nullif(max(sum_m), 0) / nullif(min(sum_m), 0)) > 0
                        then log10(nullif(max(sum_m), 0) / nullif(min(sum_m), 0))
                    else log10((nullif(max(sum_m), 0) - nullif(min(sum_m), 0)) /
                               least(abs(nullif(min(sum_m), 0)), abs(nullif(max(sum_m), 0))))
                    end                            as sum_quality,
                avg(min_m) filter (where r = 8)    as min_value,
                case
                    when (nullif(max(min_m), 0) / nullif(min(min_m), 0)) > 0
                        then log10(nullif(max(min_m), 0) / nullif(min(min_m), 0))
                    else log10((nullif(max(min_m), 0) - nullif(min(min_m), 0)) /
                               least(abs(nullif(min(min_m), 0)), abs(nullif(max(min_m), 0))))
                    end                            as min_quality,

                avg(max_m) filter (where r = 8)    as max_value,
                case
                    when (nullif(max(max_m), 0) / nullif(min(max_m), 0)) > 0
                        then log10(nullif(max(max_m), 0) / nullif(min(max_m), 0))
                    else log10((nullif(max(max_m), 0) - nullif(min(max_m), 0)) /
                               least(abs(nullif(min(max_m), 0)), abs(nullif(max(max_m), 0))))
                    end                            as max_quality,
                avg(mean_m) filter (where r = 8)   as mean_value,
                case
                    when (nullif(max(mean_m), 0) / nullif(min(mean_m), 0)) > 0
                        then log10(nullif(max(mean_m), 0) / nullif(min(mean_m), 0))
                    else log10((nullif(max(mean_m), 0) - nullif(min(mean_m), 0)) /
                               least(abs(nullif(min(mean_m), 0)), abs(nullif(max(mean_m), 0))))
                    end                            as mean_quality,
                avg(stddev_m) filter (where r = 8) as stddev_value,
                case
                    when (nullif(max(stddev_m), 0) / nullif(min(stddev_m), 0)) > 0
                        then log10(nullif(max(stddev_m), 0) / nullif(min(stddev_m), 0))
                    else log10((nullif(max(stddev_m), 0) - nullif(min(stddev_m), 0)) /
                               least(abs(nullif(min(stddev_m), 0)), abs(nullif(max(stddev_m), 0))))
                    end                            as stddev_quality,
                avg(median_m) filter (where r = 8) as median_value,
                case
                    when (nullif(max(median_m), 0) / nullif(min(median_m), 0)) > 0
                        then log10(nullif(max(median_m), 0) / nullif(min(median_m), 0))
                    else log10((nullif(max(median_m), 0) - nullif(min(median_m), 0)) /
                               least(abs(nullif(min(median_m), 0)), abs(nullif(max(median_m), 0))))
                    end                            as median_quality

         from (select r,
                      sum(z.m)                                         as sum_m,
                      min(z.m)                                         as min_m,
                      max(z.m)                                         as max_m,
                      avg(z.m)                                         as mean_m,
                      stddev(z.m)                                      as stddev_m,
                      percentile_cont(0.5) within group (order by z.m) as median_m
               from (select (:numer / nullif(:denom, 0)) as m, zoom as r from stat_h3) z
               group by r
               order by r
              ) x
     ) a
where numerator = :numer_text
  and denominator = :denom_text;
