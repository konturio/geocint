drop function if exists axis_correlation(text, text, text, text);
drop function if exists axis_correlation(text, text, text, text, text);
drop function if exists bivariate_axis_correlation(text, text, text, text, text);
create or replace function bivariate_axis_correlation(table_name text,
                                                      parameter1 text,
                                                      parameter2 text,
                                                      parameter3 text,
                                                      parameter4 text)
    returns float
as
$$
declare
    select_query float;
begin
    execute 'select corr(' || parameter1 || '/' || parameter2 || ',' || parameter3 || '/' || parameter4 || ') ' ||
            'from ' || table_name || ' where ' || parameter2 || '!= 0 and ' || parameter4 || ' !=0' into select_query;
    return select_query;
end;
$$
    language plpgsql;

drop table if exists axis_correlation;
create table axis_correlation as (
    select
        b1.param_id as x_numerator,
        b2.param_id as x_denominator,
        b3.param_id as y_numerator,
        b4.param_id as y_denominator,
        bivariate_axis_correlation('stat_h3', b1.param_id,  b2.param_id, b3.param_id, b4.param_id)
    from
        bivariate_copyrights b1,
        bivariate_copyrights b2,
        bivariate_copyrights b3,
        bivariate_copyrights b4
    where
          (x_numerator != x_denominator and y_numerator != y_denominator)
      and ((x_numerator = y_numerator and x_denominator != y_denominator) or
           (x_numerator != y_numerator and x_denominator = y_denominator))
);

