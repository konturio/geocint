drop table if exists osm_axis_parameters;

create table osm_axis_parameters
(
    parameter varchar(64)
);

insert into osm_axis_parameters (parameter)
select UNNEST(ARRAY ['count', 'area_km2', 'population', 'building_count', 'highway_length']);


------------------------

drop table if exists bivariate_axis;

create table bivariate_axis
(
    min      double precision,
    p25      double precision,
    p75      double precision,
    max      double precision,
    division varchar(64),
    divisor  varchar(64)
);


------------------------


drop function if exists calculate_bivariate_axis;

create or replace function calculate_bivariate_axis(parameter1 varchar, parameter2 varchar)
    returns void
    language plpgsql
as
$$
declare
    insert_query text;
begin
    insert_query = 'insert into bivariate_axis (min, p25, p75, max, division, divisor) ' ||
    'select round(min(' || parameter1 || ' / ' || parameter2 || '))   as min, ' ||
    'greatest(round(percentile_cont(0.25) within group (order by ' || parameter1 || ' / ' || parameter2 || ')), 2::float)   as p25, ' ||
    'round(percentile_cont(0.75) within group (order by ' || parameter1 || ' / ' || parameter2 || '))   as p75, ' ||
    'ceil(max(' || parameter1 || ' / ' || parameter2 || '))   as max, ''' ||
    parameter1  || '''   as division, ''' ||
    parameter2 || '''   as divisor ' ||
    'from osm_object_count_grid_h3_with_population ' ||
    'where ' || parameter1 || ' != 0 and ' || parameter2 || ' != 0 and zoom = 6';

    execute insert_query;
end;
$$
;

select calculate_bivariate_axis(p.parameter, p2.parameter)
from osm_axis_parameters p,
     (select parameter from osm_axis_parameters) as p2
where p2.parameter != p.parameter
and p.parameter not in ('area_km2');



analyse bivariate_axis;

