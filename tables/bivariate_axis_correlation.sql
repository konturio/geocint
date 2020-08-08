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
    where param_id not in ('1', 'one')
);

alter table tmp_bivariate_copyrights
    set (parallel_workers = 32);

drop table if exists axis_combinations;
create table axis_combinations as (
    select b1.param_id as parameter1,
           b2.param_id as parameter2,
           b3.param_id as parameter3,
           b4.param_id as parameter4
    from tmp_bivariate_copyrights b1,
         tmp_bivariate_copyrights b2,
         tmp_bivariate_copyrights b3,
         tmp_bivariate_copyrights b4
);

alter table axis_combinations
    set (parallel_workers = 32);

drop table if exists axis_correlation_new;
create table axis_correlation_new as (
    select parameter1,
           parameter2,
           parameter3,
           parameter4,
           axis_correlation('stat_h3', parameter1, parameter2, parameter3, parameter4)
    from axis_combinations
    where (parameter1 != parameter2 and parameter3 != parameter4)
      and ((parameter1 = parameter3 and parameter2 != parameter4) or
           (parameter1 != parameter3 and parameter2 = parameter4))
);

