update bivariate_axis a
set min = s.min,
    p25 = s.p25,
    p75 = s.p75,
    max = s.max
from (
         select floor(min(:numerator / :denominator::double precision))                               as min,
                percentile_disc(0.33)
                within group (order by :numerator / :denominator::double precision)::double precision as p25,
                percentile_disc(0.66)
                within group (order by :numerator / :denominator::double precision)::double precision as p75,
                ceil(max(:numerator / :denominator::double precision))                                as max
         from stat_h3
         where :numerator != 0
           and :denominator != 0
           and population > 0
     ) s
where a.numerator = :'numerator'
  and a.denominator = :'denominator';