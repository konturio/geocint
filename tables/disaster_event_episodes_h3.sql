create or replace function fix_and_wrap_geometry(geom geometry)
    returns geometry
    language sql
    stable
    parallel safe
    cost 10000
as
$$
    select
        ST_MakeValid(
            ST_UnaryUnion(
                ST_WrapX(
                    ST_WrapX(
                        ST_Union(
                            ST_MakeValid(d.geom)
                        ),
                        180, -360
                    ),
                    -180, 360
                )
            )
        )
    from ST_Dump(ST_CollectionExtract(ST_SetSRID(geom, 4326))) d;
$$;

create or replace function event_daterange_duration(rng daterange)
    returns integer
    language sql
    immutable
    parallel safe
as
$$
    -- we use custom function in order to get expectable results for one-day events.
    -- it should be 1-day long as well as events which start today and end tomorrow.
    -- it cannot be replaced with '[)' because we still have this one-day issue.
    select greatest(upper(rng) - lower(rng) - 1, 1);
$$;

create or replace function event_daterange_duration(mrng datemultirange)
    returns integer
    language sql
    immutable
    parallel safe
as
$$
    select sum(event_daterange_duration(rng))
    from unnest(mrng) rng;
$$;


drop table if exists disaster_event_episodes_severities;
create table disaster_event_episodes_severities (
    episode_severity_level int primary key,
    episode_severity text
);

insert into disaster_event_episodes_severities (episode_severity_level, episode_severity)
values
    (0, 'UNKNOWN'),
    (1, 'TERMINATION'),
    (2, 'MINOR'),
    (3, 'MODERATE'),
    (4, 'SEVERE'),
    (5, 'EXTREME')
;

drop table if exists disaster_event_episodes_validated_subdivided;
create table disaster_event_episodes_validated_subdivided as (
    select
        episode_type,
        greatest(now() at time zone 'utc' - interval '1 year', episode_startedat) episode_startedat,
        episode_endedat,
        ST_Subdivide(fix_and_wrap_geometry(geom)) geom
    from disaster_event_episodes
    left join disaster_event_episodes_severities using (episode_severity)
    where
        ((episode_type in (
            'CYCLONE',
            'DROUGHT',
            'EARTHQUAKE',
            'FLOOD',
            'STORM',
            'TORNADO',
            'TSUNAMI',
            'VOLCANO',
            'WINTER_STORM'
        )        
        and episode_severity_level > 3)
        or
        episode_type = 'WILDFIRE')

        and episode_endedat > now() at time zone 'utc' - interval '1 year'
);

create index on disaster_event_episodes_validated_subdivided using gist(geom);

drop table if exists disaster_event_episodes_h3_multidaterange;
create table disaster_event_episodes_h3_multidaterange as (
    select
        h3,
        8 resolution,
        episode_type,
        range_agg(
            daterange(episode_startedat::date, episode_endedat::date, '[]')
        ) multidaterange
    from land_polygons_h3_r8 as land
    join disaster_event_episodes_validated_subdivided as events
        on ST_Intersects(
            events.geom,
            land.h3::geometry
        )
    group by h3, episode_type
);

create index on disaster_event_episodes_h3_multidaterange using btree(resolution);

do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into disaster_event_episodes_h3_multidaterange(
                    h3, resolution, episode_type, multidaterange
                )
                select
                    h3_cell_to_parent(h3) as h3,
                    (res - 1) as resolution,
                    episode_type,
                    range_agg(r) as multidaterange
                from
                    disaster_event_episodes_h3_multidaterange,
                    unnest(multidaterange) as r
                where
                    resolution = res
                group by
                    1, episode_type;

                res = res - 1;
            end loop;
    end;
$$;

drop table if exists disaster_event_episodes_h3;
create table disaster_event_episodes_h3 as (
    select
        h3,
        event_daterange_duration(range_agg(event_time_range))::int as hazardous_days_count,
        sum(ds.duration) filter (where episode_type = 'CYCLONE')::int as cyclone_days_count,
        sum(ds.duration) filter (where episode_type = 'DROUGHT')::int as drought_days_count,
        sum(ds.duration) filter (where episode_type = 'EARTHQUAKE')::int as earthquake_days_count,
        sum(ds.duration) filter (where episode_type = 'FLOOD')::int as flood_days_count,
        sum(ds.duration) filter (where episode_type = 'VOLCANO')::int as volcano_days_count,
        sum(ds.duration) filter (where episode_type = 'WILDFIRE')::int as wildfire_days_count
        -- -- enable it when we get the data
        -- sum(ds.duration) filter (where episode_type = 'STORM') as storm_days_count,
        -- sum(ds.duration) filter (where episode_type = 'TORNADO') as tornado_days_count,
        -- sum(ds.duration) filter (where episode_type = 'TSUNAMI') as tsunami_days_count,
        -- sum(ds.duration) filter (where episode_type = 'WINTER_STORM') as winter_storm_days_count
    from disaster_event_episodes_h3_multidaterange
    left join lateral (
        select
			event_time_range,
            event_daterange_duration(event_time_range) duration
		from unnest(multidaterange) event_time_range
    ) ds on true
    group by h3
);

-- drop table if exists disaster_event_episodes_validated_subdivided;
-- drop table if exists disaster_event_episodes_h3_multidaterange;
