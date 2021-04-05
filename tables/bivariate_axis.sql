drop function if exists calculate_axis_stops(text);
drop function if exists calculate_axis_stops(text, text);
create or replace function calculate_axis_stops(parameter1 text, parameter2 text)
    returns TABLE
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
                   ' != 0 and' ||
                   ' population > 0';
    -- population > 0 is needed because stat_h3 has 65% of hexagons in
    -- unpopulated areas that skew generated histogram to be less interesting in humanitarian context.
    return query execute select_query;
end;
$$
    stable
    parallel safe;

drop table if exists stat_h3_quality;
create table stat_h3_quality as (
    select *
    from
        (
            select
                h3_to_parent(a.h3) as h3_parent,
                avg(a.count) as agg_count,
                avg(a.count_6_months) as agg_count_6_months,
                avg(a.building_count) as agg_building_count,
                avg(a.building_count_6_months) as agg_building_count_6_months,
                avg(a.highway_length) as agg_highway_length,
                avg(a.highway_length_6_months) as agg_highway_length_6_months,
                avg(a.osm_users) as agg_osm_users,
                avg(a.population) as agg_population,
                avg(a.residential) as agg_residential,
                avg(a.gdp) as agg_gdp,
                avg(a.min_ts) as agg_min_ts,
                avg(a.max_ts) as agg_max_ts,
                avg(a.avgmax_ts) as agg_avgmax_ts,
                avg(a.local_hours) as agg_local_hours,
                avg(a.total_hours) as agg_total_hours,
                avg(a.view_count) as agg_view_count,
                avg(a.area_km2) as agg_area_km2,
                avg(a.one) as agg_one,
                avg(a.total_building_count) as agg_total_building_count,
                avg(a.wildfires) as agg_wildfires,
                avg(a.covid19_vaccines) as agg_covid19_vaccines,
                avg(a.avg_slope) as agg_avg_slope,
                avg(a.forest) as agg_forest,
                avg(a.avg_ndvi) as agg_avg_ndvi,
                avg(a.covid19_confirmed) as agg_covid19_confirmed,
                avg(a.covid19_dead) as agg_covid19_dead
            from
                stat_h3 a
            where
                a.resolution between 1 and 6
            group by 1 ) a
    join stat_h3 b on a.h3_parent = b.h3
);

create or replace function estimate_bivariate_axis_quality (parameter1 text, parameter2 text)
    returns float
    language plpgsql
as
$$
declare
    quality float;
begin

    execute 'select (1.0::float-avg(' ||
            -- if we zoom in one step, will current zoom values be the same as next zoom values?
            'abs(('||parameter1||' / nullif('||parameter2||', 0)) - (agg_'||parameter1||' / nullif(agg_'||parameter2||', 0)))
            /
            nullif(('||parameter1||' / nullif('||parameter2||', 0)) + (agg_'||parameter1||' / nullif(agg_'||parameter2||', 0)), 0))' ||
            ')' ||
            -- does the denominator cover all of the cells where numerator is present?
            '* (' ||
            '(count(*) filter (where '||parameter1||' != 0 and '||parameter2||' != 0))::float ' ||
            '/ ' ||
            '(count(*) filter (where '||parameter1||' != 0))'||
            ' )'||
        'from stat_h3_quality' into quality;
    return quality;
end;
$$
    stable
    parallel safe;

drop table if exists bivariate_axis;
create table bivariate_axis as (
    select numerator,
           denominator,
           (z.f).min,
           (z.f).p25,
           (z.f).p75,
           (z.f).max,
           quality,
           '' as min_label,
           '' as p25_label,
           '' as p75_label,
           '' as max_label,
           '' as label
    from (
             select a.param_id as numerator,
                    b.param_id as denominator,
                    calculate_axis_stops(a.param_id, b.param_id) f,
                    estimate_bivariate_axis_quality(a.param_id, b.param_id) quality
             from bivariate_indicators a,
                  bivariate_indicators b
             where a.param_id != b.param_id
         ) z
);

analyse bivariate_axis;

update bivariate_axis
set
    label = 'Highway length (m/km²)'
where
      numerator = 'highway_length'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Population (ppl/km²)'
where
      numerator = 'population'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'OSM objects (n/km²)'
where
      numerator = 'count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Buildings (n/km²)'
where
      numerator = 'building_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Edits by active locals (h/km²)'
where
      numerator = 'local_hours'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Edits by all mappers (h/km²)'
where
      numerator = 'total_hours'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Map views, last 30 days (n/km²)'
where
      numerator = 'view_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'OpenStreetMap Contributors (n)'
where
      numerator = 'osm_users'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Total buildings count (n/km²)'
where
      numerator = 'total_building_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Wildfires (n/km²)'
where
      numerator = 'wildfires'
  and denominator = 'area_km2';

update bivariate_axis set label = 'Last edit (date)' where numerator = 'avgmax_ts' and denominator = 'one';

update bivariate_axis
set
    min_label = to_char(to_timestamp(min), 'DD Mon YYYY'),
    p25_label = to_char(to_timestamp(p25), 'DD Mon YYYY'),
    p75_label = to_char(to_timestamp(p75), 'DD Mon YYYY'),
    max_label = to_char(to_timestamp(max), 'DD Mon YYYY')
where
      numerator in ('min_ts', 'max_ts', 'avgmax_ts')
  and denominator = 'one';