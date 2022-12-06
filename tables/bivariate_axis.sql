drop table if exists bivariate_axis;
create table bivariate_axis as (
    select a.param_id             as numerator,
           b.param_id             as denominator,
           null::double precision as min,
           null::double precision as p25,
           null::double precision as p75,
           null::double precision as max,
           null::double precision as quality,
           ''::text               as min_label,
           ''::text               as p25_label,
           ''::text               as p75_label,
           ''::text               as max_label,
           ''::text               as label,
           null::double precision as sum_value,
           null::double precision as sum_quality,
           null::double precision as min_value,
           null::double precision as min_quality,
           null::double precision as max_value,
           null::double precision as max_quality,
           null::double precision as stddev_value,
           null::double precision as stddev_quality,
           null::double precision as median_value,
           null::double precision as median_quality,
           null::double precision as mean_value,
           null::double precision as mean_quality
    from bivariate_indicators as a,
         bivariate_indicators as b
    where b.is_base and a.param_id != b.param_id
);

-- During experiment we disabling three base indicators, but we still want to calculate overlays based on them, so we should add missing pairs to bivariate_axis
insert into bivariate_axis (numerator, denominator,min_label,p25_label,p75_label,max_label,label)
select numerator,
       denominator,
       ''::text as min_label,
       ''::text as p25_label,
       ''::text as p75_label,
       ''::text as max_label,
       ''::text as label
from (select x_numerator   as numerator,
             x_denominator as denominator
      from bivariate_overlays
      union
      select y_numerator   as numerator,
             y_denominator as denominator
      from bivariate_overlays) a
where not exists(
        select * from bivariate_axis b where a.numerator = b.numerator and a.denominator = b.denominator
    );