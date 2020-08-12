drop function if exists axis_correlation(text, text, text, text);
drop function if exists axis_correlation(text, text, text, text, text);
drop function if exists correlate_bivariate_axes(text, text, text, text, text);
create or replace function correlate_bivariate_axes(table_name text, x_num text, x_den text, y_num text, y_den text)
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
        x_num.param_id as x_num,
        x_den.param_id as x_den,
        y_num.param_id as y_num,
        y_den.param_id as y_den,
        correlate_bivariate_axes('stat_h3', x_num.param_id, x_den.param_id, y_num.param_id, y_den.param_id)
    from
        bivariate_copyrights x_num,
        bivariate_copyrights x_den,
        bivariate_copyrights y_num,
        bivariate_copyrights y_den
    where
        (x_num.param_id != y_num.param_id or x_den.param_id != y_den.param_id)
);

