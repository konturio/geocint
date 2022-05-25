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
    select
        a.param_id as numerator,
        b.param_id as denominator,
        min,
        p25,
        p75,
        max,
        quality,
        '' as min_label,
        '' as p25_label,
        '' as p75_label,
        '' as max_label,
        '' as label
    from
        bivariate_indicators                                    as a,
        bivariate_indicators                                    as b,
        calculate_axis_stops(a.param_id, b.param_id)            as f,
        estimate_bivariate_axis_quality(a.param_id, b.param_id) as quality
    where
        b.is_base and a.param_id != b.param_id
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

update bivariate_axis
set
    label = 'Number of days under earthquake impact (n/km²)'
where
      numerator = 'eathquake_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under industrial heat impact (n/km²)'
where
      numerator = 'industrial_heat_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under drough impact (n/km²)'
where
      numerator = 'drough_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under thermal anomaly impact (n/km²)'
where
      numerator = 'thermal_anomaly_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under cyclone impact (n/km²)'
where
      numerator = 'cyclone_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under wildfire impact (n/km²)'
where
      numerator = 'wildfire_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under volcano impact (n/km²)'
where
      numerator = 'volcano_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Number of days under flood impact (n/km²)'
where
      numerator = 'flood_days_count'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Forest Landcover Area (km²/km²)'
where
      numerator = 'forest'
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

update bivariate_axis
set
    label = 'Number of days per year'
where
      numerator = 'days_maxtemp_over_32c_1c'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Number of nights per year'
where
      numerator = 'days_mintemp_above_25c_1c'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Man-distance to fire brigade'
where
      numerator = 'man_distance_to_fire_brigade'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Man-distance to hospitals'
where
      numerator = 'man_distance_to_hospital'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Total Roads Estimate (m/km²)'
where
      numerator = 'total_road_length'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Distance to fire station (km)',
    p25 = 3.0, 
    p75 = 10.0
where
      numerator = 'man_distance_to_fire_brigade'
  and denominator = 'population';

update bivariate_axis
set
    label = 'OSM roads density (m/km²)'
where
      numerator = 'highway_length'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'OSM roads density (m/km²)'
where
      numerator = 'highway_length'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Meta and OSM roads density (m/km2)'
where
      numerator = 'total_road_length'
  and denominator = 'area_km2';

update bivariate_axis
set
    label = 'Foursquare Japan places count'
where
      numerator = 'foursquare_places_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Foursquare Japan visits count'
where
      numerator = 'foursquare_visits_count'
  and denominator = 'one';

update bivariate_axis
set
    label = 'Map views 30 days before 24.02.2022'
where
      numerator = 'view_count_bf2402'
  and denominator = 'one';

update bivariate_axis
set
    label = 'OSM Map Views, Jan 25-Feb 24 2022 (n/km²)'
where
      numerator = 'view_count_bf2402'
  and denominator = 'area_km2';

-- columns for advanced analytics
alter table bivariate_axis
    add column sum_value double precision,
    add column sum_quality double precision,
    add column min_value double precision,
    add column min_quality double precision,
    add column max_value double precision,
    add column max_quality double precision,
    add column stddev_value double precision,
    add column stddev_quality double precision,
    add column median_value double precision,
    add column median_quality double precision,
    add column mean_value double precision,
    add column mean_quality double precision;