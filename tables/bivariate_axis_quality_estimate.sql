update bivariate_axis a
set quality = q.quality
from (

         select (1.0::float - avg(
             -- if we zoom in one step, will current zoom values be the same as next zoom values?
                 abs((:numerator / nullif(:denominator, 0)) - (agg_:numerator / nullif(agg_:denominator, 0))) / nullif(
                         (:numerator / nullif(:denominator, 0)) + (agg_:numerator / nullif(agg_:denominator, 0)), 0)))
                    -- does the denominator cover all of the cells where numerator is present?
                        * ((count(*) filter (where :numerator != 0 and :denominator != 0))::float
                     / (count(*) filter (where :numerator != 0))) as quality
         from stat_h3_quality
     ) q
where a.numerator = :'numerator'
  and a.denominator = :'denominator';