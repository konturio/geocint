drop function if exists axis_correlation(text, text, text, text);

create or replace function axis_correlation(table_name text, parameter1 text, parameter2 text, parameter3 text,
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


drop table if exists tmp_bivariate_copyrights;
create table tmp_bivariate_copyrights as (
    select param_id
    from bivariate_copyrights
    where param_id != '1'
);

alter table tmp_bivariate_copyrights
    set (parallel_workers = 32);

drop table if exists axis_combinations;
create table axis_combinations as (
    select b1.param_id as x_numerator,
           b2.param_id as x_denominator,
           b3.param_id as y_numerator,
           b4.param_id as y_denominator
    from tmp_bivariate_copyrights b1,
         tmp_bivariate_copyrights b2,
         tmp_bivariate_copyrights b3,
         tmp_bivariate_copyrights b4
);

alter table axis_combinations
    set (parallel_workers = 32);

drop table if exists axis_correlation_new;
create table axis_correlation_new as (
    select x_numerator,
           x_denominator,
           y_numerator,
           y_denominator,
           axis_correlation('stat_h3', x_numerator, x_denominator, y_numerator, y_denominator)
    from axis_combinations
    where (x_numerator != x_denominator and y_numerator != y_denominator)
      and ((x_numerator = y_numerator and x_denominator != y_denominator) or
           (x_numerator != y_numerator and x_denominator = y_denominator))
);

