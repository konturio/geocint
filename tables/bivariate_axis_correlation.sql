drop function if exists axis_correlation(text, text, text, text
);
drop function if exists axis_correlation(text, text, text, text, text
);
drop function if exists correlate_bivariate_axes(text, text, text, text, text
);
create or replace function correlate_bivariate_axes
(
    table_name text, x_num text, x_den text, y_num text, y_den text
)
    returns float
as
$$
declare
    select_query float;
begin
    execute 'select corr(' || x_num || '/' || x_den || ',' || y_num || '/' || y_den || ') ' ||
            'from ' || table_name || ' where ' || x_den || '!= 0 and ' || y_den || ' != 0' into select_query;
    return select_query;
end;
$$
    language plpgsql;

drop table if exists bivariate_axis_correlation;
create table bivariate_axis_correlation as (
    select
        x.numerator as x_num,
        x.denominator as x_den,
        y.numerator as y_num,
        y.denominator as y_den,
        correlate_bivariate_axes('stat_h3_quality', x.numerator, x.denominator, y.numerator, y.denominator) as correlation,
        1 - ((1 - x.quality) * (1 - y.quality)) as quality
    from
        (bivariate_axis x
            inner join
                bivariate_indicators indicators_x
                    on (x.denominator = indicators_x.param_id))
            cross join
        (bivariate_axis y
            inner join
                bivariate_indicators indicators_y
                    on (y.denominator = indicators_y.param_id))
    where
          (x.numerator != y.numerator or x.denominator != y.denominator)
      and x.quality > 0.5
      and y.quality > 0.5
      and indicators_x.is_base
      and indicators_y.is_base
);