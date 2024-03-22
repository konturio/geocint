drop table if exists bivariate_axis_prod;
create table bivariate_axis_prod as (
    select *
    from bivariate_axis
    where numerator in (select indicator from prod_indicators_list)
      and denominator in (select indicator from prod_indicators_list)
);

vacuum analyze bivariate_axis;