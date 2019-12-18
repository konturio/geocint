drop function if exists calculate_axis_stops(text, text);

create or replace function calculate_axis_stops(parameter1 text, parameter2 text)
    RETURNS TABLE (min double precision, p25 double precision, p75 double precision, max double precision)
    language plpgsql
as
$$
declare
    select_query text;
begin
    select_query = 'select floor(min(' || parameter1 || ' / ' || parameter2 || '::double precision))   as min, ' ||
                   'percentile_disc(0.33) within group (order by ' || parameter1 || ' / ' || parameter2 || '::double precision)::double precision as p25, ' ||
                   'percentile_disc(0.66) within group (order by ' || parameter1 || ' / ' || parameter2 || '::double precision)::double precision as p75, ' ||
                   'ceil(max(' || parameter1 || ' / ' || parameter2 || '::double precision))   as max ' ||
                   'from osm_object_count_grid_h3_with_population ' ||
                   'where ' || parameter1 || ' != 0 and ' || parameter2 || ' != 0 and population >= 1 and zoom = 6';

    RETURN QUERY execute select_query;
end;
$$
;

drop function if exists calculate_axis_stops(text);

create or replace function calculate_axis_stops(parameter1 text)
    RETURNS TABLE (min double precision, p25 double precision, p75 double precision, max double precision)
    language plpgsql
as
$$
declare
    select_query text;
begin
    select_query = 'select floor(min(' || parameter1 || ' ))   as min, ' ||
                   'percentile_disc(0.33) within group (order by ' || parameter1 || ' )::double precision as p25, ' ||
                   'percentile_disc(0.66) within group (order by ' || parameter1 || ' )::double precision as p75, ' ||
                   'ceil(max(' || parameter1 || ' ))   as max ' ||
                   'from osm_object_count_grid_h3_with_population ' ||
                   'where population >= 1 and zoom = 6';

    RETURN QUERY execute select_query;
end;
$$
;


drop table if exists bivariate_axis;

create table bivariate_axis as (
    with axis_parameters as (
        select UNNEST(ARRAY ['count', 'area_km2', 'population', 'building_count', 'highway_length', 'amenity_count',
            'osm_users', 'osm_users_recent', 'top_user_objects', 'avg_ts', 'max_ts', 'p90_ts']) as parameter
    )
    select a.parameter as numerator, b.parameter as denominator, f.*
    from axis_parameters a,
         axis_parameters b,
         calculate_axis_stops(a.parameter, b.parameter) f
    where a.parameter != b.parameter
      and a.parameter not in ('area_km2')
    UNION
    select a.parameter as numerator, '1' as denominator, f.*
    from axis_parameters a,
         calculate_axis_stops(a.parameter) f);

analyse bivariate_axis;