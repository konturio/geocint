-- This aggregated function generates weighted centroid based on cost value
DROP AGGREGATE IF EXISTS ST_WeightedCentroids(geometry, DOUBLE PRECISION);
DROP FUNCTION IF EXISTS st_weightedcentroids_sfunc(jsonb, geometry, DOUBLE PRECISION);
DROP FUNCTION IF EXISTS st_weightedcentroids_finalfn(jsonb);

-- State transition function
-- call one time per pow to calculate intermadiate result
CREATE OR REPLACE FUNCTION st_weightedcentroids_sfunc(
    state JSONB,
    geom geometry,
    cost DOUBLE PRECISION
)
RETURNS JSONB
AS
$$
DECLARE
    cx DOUBLE PRECISION := ST_X(ST_Centroid(ST_Transform(geom,4326))) * cost;
    cy DOUBLE PRECISION := ST_Y(ST_Centroid(ST_Transform(geom,4326))) * cost;
    sum_cost DOUBLE PRECISION := cost;
BEGIN
    -- for first line
    IF state IS NULL OR state = '{}'::jsonb THEN
        RETURN jsonb_build_object('sum_x', cx, 'sum_y', cy, 'sum_cost', sum_cost);
    ELSE
        RETURN jsonb_build_object(
            'sum_x', (state->>'sum_x')::FLOAT + cx,
            'sum_y', (state->>'sum_y')::FLOAT + cy,
            'sum_cost', (state->>'sum_cost')::FLOAT + sum_cost
        );
    END IF;
END;
$$
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE;

-- Final function
-- compute actual result from accumulated state
CREATE OR REPLACE FUNCTION st_weightedcentroids_finalfn(
    state JSONB
)
RETURNS geometry
AS
$$
DECLARE
    avg_x DOUBLE PRECISION;
    avg_y DOUBLE PRECISION;
BEGIN
    IF state IS NULL OR state = '{}'::jsonb THEN
        RETURN NULL;
    END IF;

    avg_x := (state->>'sum_x')::FLOAT / (state->>'sum_cost')::FLOAT;
    avg_y := (state->>'sum_y')::FLOAT / (state->>'sum_cost')::FLOAT;

    RETURN ST_SetSRID(ST_MakePoint(avg_x, avg_y), 4326);
END;
$$
LANGUAGE plpgsql
IMMUTABLE
PARALLEL SAFE;

-- Aggregate definition
CREATE AGGREGATE ST_WeightedCentroids(
    geom geometry,
    cost DOUBLE PRECISION
) (
    SFUNC = st_weightedcentroids_sfunc,
    STYPE = jsonb,
    FINALFUNC = st_weightedcentroids_finalfn,
    INITCOND = '{}'
);
