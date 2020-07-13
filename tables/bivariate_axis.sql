drop function if exists calculate_axis_stops(text, text);

create or replace function calculate_axis_stops(parameter1 text, parameter2 text)
    RETURNS TABLE
            (
                min double precision,
                p25 double precision,
                p75 double precision,
                max double precision
            )
    language plpgsql
as
$$
declare
    select_query text;
begin
    select_query = 'select floor(min(' || parameter1 || ' / ' || parameter2 || '::double precision))   as min, ' ||
                   'percentile_disc(0.33) within group (order by ' || parameter1 || ' / ' || parameter2 ||
                   '::double precision)::double precision as p25, ' ||
                   'percentile_disc(0.66) within group (order by ' || parameter1 || ' / ' || parameter2 ||
                   '::double precision)::double precision as p75, ' ||
                   'ceil(max(' || parameter1 || ' / ' || parameter2 || '::double precision))   as max ' ||
                   'from stat_h3 ' ||
                   'where ' || parameter1 || ' != 0 and ' || parameter2 ||
                   ' != 0 and population > 0'; -- population > 0 is needed because stat_h3 has 65% of hexagons in unpopulated areas that skew generated histogram to be less interesting in humanitarian context.

    RETURN QUERY execute select_query;
end;
$$;

drop function if exists calculate_axis_stops(text);

create or replace function calculate_axis_stops(parameter1 text)
    RETURNS TABLE
            (
                min double precision,
                p25 double precision,
                p75 double precision,
                max double precision
            )
    language plpgsql
as
$$
declare
    select_query text;
begin
    select_query = 'select floor(min(' || parameter1 || ' ))::double precision   as min, ' ||
                   'percentile_disc(0.33) within group (order by ' || parameter1 || ' )::double precision as p25, ' ||
                   'percentile_disc(0.66) within group (order by ' || parameter1 || ' )::double precision as p75, ' ||
                   'ceil(max(' || parameter1 || ' ))::double precision   as max ' ||
                   'from stat_h3 ' ||
                   'where population > 0'; -- population > 0 is needed because stat_h3 has 65% of hexagons in unpopulated areas that skew generated histogram to be less interesting in humanitarian context.

    RETURN QUERY execute select_query;
end;
$$
;


drop table if exists bivariate_axis;

create table bivariate_axis as (
    with axis_parameters as (
        select param_id as parameter from bivariate_copyrights where param_id not in ('1', 'top_user', 'one')
    )
    select a.parameter as numerator,
           b.parameter as denominator,
           f.*,
           ''          as min_label,
           ''          as p25_label,
           ''          as p75_label,
           ''          as max_label,
           ''          as label
    from axis_parameters a,
         axis_parameters b,
         calculate_axis_stops(a.parameter, b.parameter) f
    where a.parameter != b.parameter
      and a.parameter not in ('area_km2')
    UNION ALL
    select a.parameter as numerator,
           'one'       as denominator,
           f.*,
           ''          as min_label,
           ''          as p25_label,
           ''          as p75_label,
           ''          as max_label,
           ''          as label
    from axis_parameters a,
         calculate_axis_stops(a.parameter) f);

analyse bivariate_axis;

update bivariate_axis
set label = 'Highway length (m/km²)'
where numerator = 'highway_length'
  and denominator = 'area_km2';

update bivariate_axis
set label = 'Population (ppl/km²)'
where numerator = 'population'
  and denominator = 'area_km2';

update bivariate_axis
set label = 'OSM objects (n/km²)'
where numerator = 'count'
  and denominator = 'area_km2';

update bivariate_axis
set label = 'Buildings (n/km²)'
where numerator = 'building_count'
  and denominator = 'area_km2';

update bivariate_axis
set label = 'Edits by active locals (h/km²)'
where numerator = 'local_hours'
  and denominator = 'area_km2';

update bivariate_axis
set label = 'Edits by all mappers (h/km²)'
where numerator = 'total_hours'
  and denominator = 'area_km2';

update bivariate_axis
set label = 'Map views for the last 30 days (n/km²)'
where numerator = 'view_count'
  and denominator = 'area_km2';

update bivariate_axis
set label = 'OpenStreetMap Contributors (n)'
where numerator = 'osm_users'
  and denominator = 'one';

update bivariate_axis
set label = '90% mapped before (date)'
where numerator = 'p90_ts'
  and denominator = 'one';

update bivariate_axis
set min_label = to_char(to_timestamp(min), 'DD Mon YYYY'),
    p25_label = to_char(to_timestamp(p25), 'DD Mon YYYY'),
    p75_label = to_char(to_timestamp(p75), 'DD Mon YYYY'),
    max_label = to_char(to_timestamp(max), 'DD Mon YYYY')
where numerator = 'max_ts'
  and denominator = 'one';

update bivariate_axis
set min_label = to_char(to_timestamp(min), 'DD Mon YYYY'),
    p25_label = to_char(to_timestamp(p25), 'DD Mon YYYY'),
    p75_label = to_char(to_timestamp(p75), 'DD Mon YYYY'),
    max_label = to_char(to_timestamp(max), 'DD Mon YYYY')
where numerator = 'p90_ts'
  and denominator = 'one';

update bivariate_axis
set min_label = to_char(to_timestamp(min), 'DD Mon YYYY'),
    p25_label = to_char(to_timestamp(p25), 'DD Mon YYYY'),
    p75_label = to_char(to_timestamp(p75), 'DD Mon YYYY'),
    max_label = to_char(to_timestamp(max), 'DD Mon YYYY')
where numerator = 'avg_ts'
  and denominator = 'one';
