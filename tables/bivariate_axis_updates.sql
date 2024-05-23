update bivariate_axis a
set
    label = coalesce(b.label, a.label),
    min = coalesce(b.min, a.min),
    max = coalesce(b.max, a.max),
    p25 = coalesce(b.p25, a.p25),
    p75 = coalesce(b.p75, a.p75)
from bivariate_axis_overrides b
where
    a.numerator = b.numerator and
    a.denominator = b.denominator;

update bivariate_axis
set
    min_label = to_char(to_timestamp(min), 'DD Mon YYYY'),
    p25_label = to_char(to_timestamp(p25), 'DD Mon YYYY'),
    p75_label = to_char(to_timestamp(p75), 'DD Mon YYYY'),
    max_label = to_char(to_timestamp(max), 'DD Mon YYYY')
where
      numerator in ('min_ts', 'max_ts', 'avgmax_ts')
  and denominator = 'one';
