-- ➊ one row per hex, keep the cheapest agg_cost we have seen so far
drop TABLE if exists hex_owner;
CREATE TABLE hex_owner (
    h3           h3index PRIMARY KEY,
    airport_id   bigint,
    cost         float  -- network distance / agg_cost
);


DO $$
DECLARE
    airport RECORD;
    reachable BIGINT;
    population_resolution int := 8;
    roads_resolution int := 8;
    group_to_resolution int := 8;
BEGIN
    FOR airport IN
        SELECT id, geom
        FROM airports_india
        WHERE name !~ 'Abandoned' and disused is distinct from 'yes' and landuse is distinct from  'military' and access is distinct from 'private'
        --WHERE abandoned IS DISTINCT FROM 'yes'
    LOOP
        RAISE NOTICE 'Processing airport id=%', airport.id;

        -- Replace the event geometry with the current airport
        DROP TABLE IF EXISTS event;
        CREATE TEMP TABLE event AS
        SELECT ST_Transform(ST_Buffer(airport.geom::geography, 10000)::geometry, 3857) AS geom;

        -- Run the rest of your SQL logic here:
        -- (For clarity, you can factor your current routing SQL into a SQL file like `run_routing_for_airport.sql` and execute it using `\i run_routing_for_airport.sql`)
        -- Alternatively, inline the entire logic between BEGIN ... END

drop table if exists tmp_stat_h3;
create table tmp_stat_h3 (h3, danger_estimate, passability, capacity, population, geom) as
with event_buffer(geom) as (
    -- TODO: 60km hardcoded buffer radius
    select ST_Transform(ST_Buffer(
    --        ST_SetSRID(ST_Point(
                    -- -156.3270, 20.8215 -- Maui
  --                  -83.52858, 35.78243 -- Sevier county
--    ), 4326)::geography, 60000)::geometry, 4326)
        ST_Transform(geom, 4326)::geography, 180000)::geometry, 4326) from event
),
-- all h3 cells of simulation field
population_hexes(h3) as materialized (
    select h3_polygon_to_cells(ST_Subdivide(event_buffer.geom), population_resolution) from event_buffer
),
road_hexes(h3) as materialized (
    select h3_polygon_to_cells(ST_Subdivide(event_buffer.geom), roads_resolution) from event_buffer
),
population (h3, original_h3, population) as (
    select h3_cell_to_center_child(h3, roads_resolution), h3, indicator_value
    from stat_h3_transposed s
    join population_hexes using(h3)
    where indicator_uuid = (
        select internal_id from bivariate_indicators_metadata
        where owner = 'disaster.ninja' and param_id = 'population' and state = 'READY' order by date desc limit 1)
),
accommodation_capacity (h3, capacity) as (
    select h3, population from population
),
-- h3 cells inside a disaster shape
danger_zones(h3, danger_estimate) as (
    select population.h3, 1000
    from stat_h3_geom st
    join population on (population.original_h3 = st.h3), event
    where st_intersects(st.geom, event.geom)
        and resolution = population_resolution
),
passable_roads (h3, passability) as (
    select h3, indicator_value
    from stat_h3_transposed s
    join road_hexes using(h3)
    where indicator_uuid = (
        select internal_id from bivariate_indicators_metadata
        where owner = 'disaster.ninja' and param_id = 'motor_vehicle_road_length' and state = 'READY' order by date desc limit 1)
)
select h3, sum(danger_estimate), sum(passability), sum(capacity), sum(population),
        ST_Transform(h3_cell_to_boundary_geometry(h3), 3857) from (
    select h3, danger_estimate,	null::float passability, null::float capacity, 1000::float population from danger_zones
    union all
    select h3, null::float, passability, null::float,   null::float from passable_roads
    union all
    select h3, null::float, null::float, capacity,      null::float from accommodation_capacity
    union all
    select h3, null::float, null::float, null::float,   population  from population
) group by h3;

update tmp_stat_h3
set capacity = 0
where danger_estimate > 0;

-- Create routing graph with edge costs
drop table if exists edges;
set work_mem = '10GB';

create table edges as
select
    distinct on (d1.h3, d2.h3)
    h3index_to_bigint(d1.h3) as source,
    d1.h3 source_h3,
    h3index_to_bigint(d2.h3) as target,
    d2.h3 target_h3,
    st_makeline(
        h3_cell_to_lat_lng(d1.h3)::geometry,
        h3_cell_to_lat_lng(d2.h3)::geometry) geom,
    case
        -- TODO: magic numbers 1000000, 700000 are chosen to be greater than max passability for large hexagons
        when d1.danger_estimate > 0 or d2.danger_estimate > 0 then 1000000 -- high weight for danger zones
        else
            coalesce((select max(passability) + 111 from tmp_stat_h3) - d1.passability, 700000)
    end as cost
from tmp_stat_h3 d1,
lateral (
    select *
    from h3_grid_ring_unsafe(d1.h3, 1) r
    join tmp_stat_h3 t on t.h3=r) d2
    -- remove duplicated edges (they're now undirected)
where h3index_to_bigint(d1.h3) > h3index_to_bigint(d2.h3);

-- Add indices for pgRouting
alter table edges add column edge_id serial primary key;
create index on edges(source);
create index on edges(target);

drop table if exists routes;
create table routes as
select *
from pgr_dijkstra(
    'select edge_id as id, source, target, cost from edges',
    -- start points are inside disaster:
    (select array_agg(h3index_to_bigint(h3)) from (
        -- to reduce the number of vertices, cell -> parent -> center cell clustering is used
        select h3_cell_to_center_child(h3_cell_to_parent(h3, group_to_resolution), roads_resolution) h3
        from tmp_stat_h3
        where danger_estimate > 0
        group by h3_cell_to_parent(h3, group_to_resolution)
        order by sum(population) desc
        -- limits are set so pgr_dijkstra fits in RAM
        limit 30)
    ),
    -- start points are outside disaster:
    (select array_agg(h3index_to_bigint(h3)) from (
        select h3_cell_to_center_child(h3_cell_to_parent(h3, group_to_resolution), roads_resolution) h3
        from tmp_stat_h3
        where capacity > 0
        group by h3_cell_to_parent(h3, group_to_resolution)
        order by sum(population) desc
        limit 700)
    ),
    directed := false
);

/* pick one row per start_hex (seq = max ⇒ last step of the path) */
WITH cheapest AS (
    SELECT DISTINCT ON (r.start_vid)
           start_h3.h3,
           airport.id      AS airport_id,
           r.agg_cost      AS cost
    FROM   routes r
    JOIN   tmp_stat_h3 start_h3
           ON r.start_vid = h3index_to_bigint(start_h3.h3)
    WHERE  r.node = r.end_vid              -- last record of the path
    ORDER  BY r.start_vid, r.agg_cost      -- keep the cheapest
)
INSERT INTO hex_owner AS ho (h3, airport_id, cost)
SELECT h3, airport_id, cost
FROM   cheapest
ON CONFLICT (h3)            -- hex already assigned?
DO UPDATE                    -- keep the cheaper one
      SET (airport_id, cost) = (EXCLUDED.airport_id, EXCLUDED.cost)
      WHERE EXCLUDED.cost < ho.cost;      -- only overwrite if better

--select count(0) route_count_pgr_dijkstra from routes;

---- Join routes with relevant data
--drop table if exists route_segments;
--create table route_segments as
--select
--    r.seq seq,
--    e.source source,
--    e.target target,
--    r.start_vid path_start,
--    r.end_vid path_end,
--    -- for equal (source, target) tuple there can be 2 distinct geometries depending on edge orientation in current path
--    ST_SetSRID(st_makeline(
--        h3_cell_to_lat_lng(case node when source then source_h3 else target_h3 end)::geometry,
--        h3_cell_to_lat_lng(case node when source then target_h3 else source_h3 end)::geometry), 4326) geom,
--    start_h3.population as population_in_danger,
--    end_h3.capacity as cell_capacity,
--    sum(end_h3.capacity) over (partition by start_h3.h3) as total_reachable_capacity
--from routes r
--join edges e on (r.edge = e.edge_id)
--join tmp_stat_h3 start_h3 on r.start_vid = h3index_to_bigint(start_h3.h3)
--join tmp_stat_h3 end_h3 on r.end_vid = h3index_to_bigint(end_h3.h3)
--where
--    r.end_vid in (select h3index_to_bigint(h3) from tmp_stat_h3 where capacity > 0);
--
---- set of directed edges from all paths with amount of people travelling on each 
--drop table if exists evacuation_estimates;
--create table evacuation_estimates as
--select
--    rs.source,
--    rs.target,
--    path_start,
--    path_end,
--    rs.population_in_danger,
--    rs.geom,
--    rs.cell_capacity,
--    rs.total_reachable_capacity,
--    rs.population_in_danger * (rs.cell_capacity::float / rs.total_reachable_capacity::float) as estimated_evacuees
--from route_segments rs;
--
--
---- this is aggregated *undirected* graph of all edges:
---- each edge has a sum of people travelling through it, even if they has different start and/or end points
--drop table if exists evac_agg;
--create table evac_agg as
--select source, target, sum(estimated_evacuees) estimated_evacuees, max(geom) geom
--from evacuation_estimates
--group by 1,2;
--
--
--        -- After evac_agg is created, compute the reachable population:
--        SELECT SUM(indicator_value) INTO reachable
--        FROM stat_h3_transposed
--        WHERE h3 IN (
--            SELECT DISTINCT target::h3index FROM evac_agg
--        )
--        AND indicator_uuid = (
--            SELECT internal_id
--            FROM bivariate_indicators_metadata
--            WHERE owner = 'disaster.ninja'
--              AND param_id = 'population'
--              AND state = 'READY'
--            ORDER BY date DESC
--            LIMIT 1
--        );
--
--        -- Update the airport with the result
--        UPDATE airports_india
--        SET reachable_population = COALESCE(reachable, 0)
--        WHERE id = airport.id;
--
--        RAISE NOTICE 'Airport id=% -> reachable population = %', airport.id, reachable;
    END LOOP;
END$$;

UPDATE airports_india a
SET    closest_reachable_population = COALESCE(pop.reach, 0)
FROM  (
    SELECT airport_id,
           SUM(t.indicator_value) AS reach
    FROM   hex_owner            ho
    JOIN   stat_h3_transposed   t USING (h3)
    WHERE  t.indicator_uuid = (
             SELECT internal_id
             FROM   bivariate_indicators_metadata
             WHERE  owner = 'disaster.ninja'
             AND    param_id = 'population'
             AND    state = 'READY'
             ORDER  BY date DESC
             LIMIT 1)
    GROUP  BY airport_id
) pop
WHERE a.id = pop.airport_id;

