create or replace function calculate_validated_input(geom geometry)
    returns geometry
    language sql
    stable
    parallel safe
    cost 10000
as
$$
    select ST_MakeValid(
        ST_Transform(
            ST_UnaryUnion(
                ST_WrapX(ST_WrapX(
                    ST_Union(
                        ST_MakeValid(d.geom)),
                    180, -360), -180, 360)),
            3857))
    from ST_Dump(ST_CollectionExtract(ST_SetSRID(geom, 4326))) d;
$$;

drop table if exists disaster_event_episodes_severities;
create table disaster_event_episodes_severities (
    episode_severity_level int primary key,
    episode_severity text
);

insert into disaster_event_episodes_severities (episode_severity_level, episode_severity)
values
    (0, 'UNKNOWN'),
    (1, 'MINOR'),
    (2, 'MODERATE'),
    (3, 'SEVERE'),
    (4, 'EXTREME'),
    (5, 'TERMINATION')
;

drop table if exists disaster_event_episodes_validated_subdivided;
create table disaster_event_episodes_validated_subdivided as (
    select
        episode_type,
        greatest(now() at time zone 'utc' - interval '1 year', episode_starteda) episode_starteda,
        episode_endedat,
        ST_Subdivide(calculate_validated_input(geom)) geom
    from disaster_event_episodes
    left join disaster_event_episodes_severities using (episode_severity)
    where
        episode_type in (
            'CYCLONE',
            'DROUGHT',
            'EARTHQUAKE',
            'FLOOD',
            'STORM',
            'TORNADO',
            'TSUNAMI',
            'VOLCANO',
            'WILDFIRE',
            'WINTER_STORM'
        )
        and episode_endedat > now() at time zone 'utc' - interval '1 year'
        and episode_severity_level > 2
);

create index on disaster_event_episodes_validated_subdivided using gist(geom);

drop table if exists disaster_event_episodes_h3_multidaterange;
create table disaster_event_episodes_h3_multidaterange as (
    select
        h3,
        8 resolution,
        episode_type,
        range_agg(
            daterange(episode_starteda::date, episode_endedat::date, '[]')
        ) multidaterange
    from land_polygons_h3_r8
    join disaster_event_episodes_validated_subdivided
        on ST_Intersects(
            disaster_event_episodes_validated_subdivided.geom,
            land_polygons_h3_r8.geom
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
                select h3_to_parent(h3) as h3,
                    (res - 1) as resolution,
                    episode_type,
                    range_agg(r) as multidaterange
                from disaster_event_episodes_h3_multidaterange, unnest(multidaterange) as r
                where resolution = res
                group by h3_to_parent(h3), episode_type;

                res = res - 1;
            end loop;
    end;
$$;

drop table if exists disaster_event_episodes_h3;
create table disaster_event_episodes_h3 as (
    select
        h3,
        (
            select sum(upper(rng) - lower(rng)) duration from unnest(range_agg(ds.event_time_range)) rng
        ) as hazardous_days_count,
        sum(ds.duration) filter (where episode_type = 'CYCLONE') as cyclone_days_count,
        sum(ds.duration) filter (where episode_type = 'DROUGHT') as drought_days_count,
        sum(ds.duration) filter (where episode_type = 'EARTHQUAKE') as eathquake_days_count,
        sum(ds.duration) filter (where episode_type = 'FLOOD') as flood_days_count,
        sum(ds.duration) filter (where episode_type = 'VOLCANO') as volcano_days_count,
        sum(ds.duration) filter (where episode_type = 'WILDFIRE') as wildfire_days_count
        -- -- enable it when we get the data
        -- sum(ds.duration) filter (where episode_type = 'STORM') as storm_days_count,
        -- sum(ds.duration) filter (where episode_type = 'TORNADO') as tornado_days_count,
        -- sum(ds.duration) filter (where episode_type = 'TSUNAMI') as tsunami_days_count,
        -- sum(ds.duration) filter (where episode_type = 'WINTER_STORM') as winter_storm_days_count
    from disaster_event_episodes_h3_multidaterange
    left join lateral (
        select
			event_time_range,
            upper(event_time_range) - lower(event_time_range) duration
		from unnest(multidaterange) event_time_range
    ) ds on true
    group by h3
);

drop table if exists disaster_event_episodes_validated_subdivided;
drop table if exists disaster_event_episodes_h3_multidaterange;
