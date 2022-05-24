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

drop table if exists disaster_event_episodes_validated_subdivided;
create table disaster_event_episodes_validated_subdivided as (
    select
        episode_type,
        episode_startedA,
        episode_endedAt,
        ST_Subdivide(calculate_validated_input(geom)) geom
    from disaster_event_episodes
);

create index on disaster_event_episodes_validated_subdivided using gist(geom);

drop table if exists disaster_event_episodes_h3_multidaterange;
create table disaster_event_episodes_h3_multidaterange as (
    select
        h3,
        8 resolution,
        episode_type,
        range_agg(daterange(episode_starteda::date, episode_endedat::date, '[]')) multidaterange
    from land_polygons_h3_r8
    join disaster_event_episodes_validated_subdivided
    on ST_Intersects(disaster_event_episodes_validated_subdivided.geom, land_polygons_h3_r8.geom)
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
                insert into disaster_event_episodes_h3_multidaterange(h3, resolution, episode_type, multidaterange)
                select h3_to_parent(h3) as h3,
                    (res - 1) as resolution,
                    episode_type,
                    range_agg(r) as multidaterange
                from disaster_event_episodes_h3_multidaterange, unnest(multidaterange) as r
                where resolution = res
                group by h3, episode_type;
                res = res - 1;
            end loop;
    end;
$$;

drop table if exists disaster_event_episodes_h3;
create table disaster_event_episodes_h3 as (
    select
        h3,
        sum(ds.duration) filter (where episode_type = 'EARTHQUAKE') as eathquake_days_count,
        sum(ds.duration) filter (where episode_type = 'WILDFIRE') as wildfire_days_count,
        sum(ds.duration) filter (where episode_type = 'INDUSTRIAL_HEAT') as industrial_heat_days_count,
        sum(ds.duration) filter (where episode_type = 'OTHER') as other_days_count,
        sum(ds.duration) filter (where episode_type = 'SITUATION') as situation_days_count,
        sum(ds.duration) filter (where episode_type = 'DROUGHT') as drough_days_count,
        sum(ds.duration) filter (where episode_type = 'THERMAL_ANOMALY') as thermal_anomaly_days_count,
        sum(ds.duration) filter (where episode_type = 'CYCLONE') as cyclone_days_count,
        sum(ds.duration) filter (where episode_type = 'VOLCANO') as volcano_days_count,
        sum(ds.duration) filter (where episode_type = 'FLOOD') as flood_days_count
    from disaster_event_episodes_h3_multidaterange
    left join lateral (
        select upper(r) - lower(r) duration
        from unnest(disaster_event_episodes_h3_multidaterange.multidaterange) r
    ) ds on true
    group by h3
);

drop table if exists disaster_event_episodes_validated_subdivided;
drop table if exists disaster_event_episodes_h3_multidaterange;
