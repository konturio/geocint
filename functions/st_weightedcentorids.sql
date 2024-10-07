-- This aggregated function generates weighted centroid based on cost value
drop aggregate if exists st_weightedcentroids(geometry, double precision);
drop function if exists st_weightedcentroids_sfunc(jsonb, geometry, double precision);
drop function if exists st_weightedcentroids_finalfn(jsonb);

-- State transition function
-- call one time per row to calculate intermediate result
create or replace function st_weightedcentroids_sfunc(state jsonb,
                                                      geom geometry,
                                                      cost double precision
)
    returns jsonb
as
$$
declare
    cx       double precision := st_x(st_centroid(st_transform(geom, 3857))) * cost;
    cy       double precision := st_y(st_centroid(st_transform(geom, 3857))) * cost;
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
create or replace function st_weightedcentroids_finalfn(state jsonb
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

    return st_transform(st_setsrid(st_makepoint(avg_x, avg_y), 3857), 4326);
end;
$$
    language plpgsql
    immutable
    parallel safe;

-- Aggregate definition
create aggregate st_weightedcentroids(geom geometry,
                                      cost double precision
)
(
    sfunc = st_weightedcentroids_sfunc,
    stype = jsonb,
    finalfunc = st_weightedcentroids_finalfn,
    initcond = '{}',
    parallel = safe
);
