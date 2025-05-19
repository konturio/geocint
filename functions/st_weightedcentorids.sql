-- This aggregated function generates weighted centroid based on cost value
drop aggregate if exists ST_Weightedcentroids(geometry, double precision);
drop function if exists ST_Weightedcentroids_sfunc(jsonb, geometry, double precision);
drop function if exists ST_Weightedcentroids_finalfn(jsonb);

-- State transition function
-- call one time per row to calculate intermediate result
create or replace function ST_Weightedcentroids_sfunc(state jsonb,
                                                      geom geometry,
                                                      cost double precision
)
    returns jsonb
as
$$
declare
    cx       double precision := ST_X(ST_centroid(ST_Transform(geom, 3857))) * cost;
    cy       double precision := ST_Y(ST_centroid(ST_Transform(geom, 3857))) * cost;
    sum_cost double precision := cost;
begin
    -- for first line
    if state is null or state = '{}'::jsonb then
        return jsonb_build_object('sum_x', cx, 'sum_y', cy, 'sum_cost', sum_cost);
    else
        return jsonb_build_object(
                'sum_x', (state -> 'sum_x')::float + cx,
                'sum_y', (state -> 'sum_y')::float + cy,
                'sum_cost', (state -> 'sum_cost')::float + sum_cost
            );
    end if;
end;
$$
    language plpgsql
    immutable
    parallel safe;

-- Final function
-- compute actual result from accumulated state
create or replace function ST_Weightedcentroids_finalfn(state jsonb
)
    returns geometry
as
$$
declare
    avg_x double precision;
    avg_y double precision;
begin
    if state is null or state = '{}'::jsonb then
        return null;
    end if;

    avg_x := (state -> 'sum_x')::float / (state -> 'sum_cost')::float;
    avg_y := (state -> 'sum_y')::float / (state -> 'sum_cost')::float;

    return ST_Transform(ST_SetSRID(ST_makepoint(avg_x, avg_y), 3857), 4326);
end;
$$
    language plpgsql
    immutable
    parallel safe;

-- Aggregate definition
create aggregate ST_Weightedcentroids(geom geometry,
                                      cost double precision
)
(
    sfunc = ST_Weightedcentroids_sfunc,
    stype = jsonb,
    finalfunc = ST_Weightedcentroids_finalfn,
    initcond = '{}',
    parallel = safe
);
