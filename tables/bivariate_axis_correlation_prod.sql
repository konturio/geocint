drop table if exists bivariate_axis_correlation_prod;
create table bivariate_axis_correlation_prod as (
    select *
    from bivariate_axis_correlation
    where x_num in (select indicator from prod_indicators_list)
      and y_num in (select indicator from prod_indicators_list)
      and x_den in (select indicator from prod_indicators_list)
      and y_den in (select indicator from prod_indicators_list)
);