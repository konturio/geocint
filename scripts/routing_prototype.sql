-- task #20619
-- This script is supposed to run on insights-api-db, where all necessary tables exist.
--   while true; do kubectl port-forward -n test-insights-api pod/db-insights-api-hwn02-h8g8-0 5444:5432; done
--   psql -h localhost -p 5444 -U insights-api -f routing_prototype.sql
-- Script creates some tables (not temporary, but re-created each run) with intermediate and final results.
-- How to view results in QGIS:
-- execute SQL "table evac_agg" -> select geom column -> load as new layer
-- style for undirected road load: symbology -> graduated -> width by estimated_evacuees -> classify
-- style for directed evacuation: symbology -> replace line with arrow (in SQL choose evac_agg_directed)

-- TODO: hardcoded resolution - edges graph for routing will be constructed by res 8
\set resolution 8
-- TODO: hardcoded start/end points groupping resolution - used to reduce the number of paths.
-- should be closer to :resolution if disaster area is small, should be less otherwise
\set group_to_resolution 7

drop table if exists tmp_stat_h3;
create table tmp_stat_h3 (h3, danger_estimate, passability, capacity, population, geom) as
with event(geom) as (
    -- TODO: replace with actual disaster shape (polygon or multipolygon)
    select ST_Transform(ST_Buffer(ST_SetSRID(ST_Point(-156.3270,20.8215), 4326)::geography, 5000)::geometry, 3857)
),
event_buffer(geom) as (
    -- TODO: 40km hardcoded buffer radius
    select ST_Transform(ST_Buffer(ST_SetSRID(ST_Point(-156.3270,20.8215), 4326)::geography, 40000)::geometry, 3857)
),
-- all h3 cells of simulation field
hexes(h3) as materialized (
    select h3
    from stat_h3_geom st, event_buffer
    where ST_Intersects(st.geom, event_buffer.geom)
        and resolution = :resolution
),
population (h3, population) as (
    select h3, indicator_value
    from stat_h3_transposed s
    join hexes using(h3)
    where indicator_uuid = (
        select internal_id from bivariate_indicators_metadata
        where owner = 'disaster.ninja' and param_id = 'population' and state = 'READY' order by date desc limit 1)
),
accommodation_capacity (h3, capacity) as (
    select * from population
),
-- h3 cells inside a disaster shape
danger_zones(h3, danger_estimate) as (
    select h3, 1000
    from stat_h3_geom st
    join population using(h3), event
    where ST_Intersects(st.geom, event.geom)
        and resolution = :resolution
),
passable_roads (h3, passability) as (
    select h3, indicator_value
    from stat_h3_transposed s
    join hexes using(h3)
    where indicator_uuid = (
        select internal_id from bivariate_indicators_metadata
        where owner = 'disaster.ninja' and param_id = 'highway_length' and state = 'READY' order by date desc limit 1)
)
select h3, sum(danger_estimate), sum(passability), sum(capacity), sum(population),
        ST_Transform(h3_cell_to_boundary_geometry(h3), 3857) from (
    select h3, danger_estimate,	null::float passability, null::float capacity, null::float population from danger_zones
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
    ST_MakeLine(
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
        select h3_cell_to_center_child(h3_cell_to_parent(h3, :group_to_resolution), 8) h3
        from tmp_stat_h3
        where danger_estimate > 0
        group by h3_cell_to_parent(h3, :group_to_resolution)
        order by sum(population) desc
        -- limits are set so pgr_dijkstra fits in RAM
        limit 30)
    ),
    -- start points are outside disaster:
    (select array_agg(h3index_to_bigint(h3)) from (
        select h3_cell_to_center_child(h3_cell_to_parent(h3, :group_to_resolution), 8) h3
        from tmp_stat_h3
        where capacity > 0
        group by h3_cell_to_parent(h3, :group_to_resolution)
        order by sum(population) desc
        limit 700)
    ),
    directed := false
);

select count(0) route_count_pgr_dijkstra from routes;

-- Join routes with relevant data
drop table if exists route_segments;
create table route_segments as
select
    r.seq seq,
    e.source source,
    e.target target,
    r.start_vid path_start,
    r.end_vid path_end,
    -- for equal (source, target) tuple there can be 2 distinct geometries depending on edge orientation in current path
    ST_SetSRID(ST_MakeLine(
        h3_cell_to_lat_lng(case node when source then source_h3 else target_h3 end)::geometry,
        h3_cell_to_lat_lng(case node when source then target_h3 else source_h3 end)::geometry), 4326) geom,
    start_h3.population as population_in_danger,
    end_h3.capacity as cell_capacity,
    sum(end_h3.capacity) over (partition by start_h3.h3) as total_reachable_capacity
from routes r
join edges e on (r.edge = e.edge_id)
join tmp_stat_h3 start_h3 on r.start_vid = h3index_to_bigint(start_h3.h3)
join tmp_stat_h3 end_h3 on r.end_vid = h3index_to_bigint(end_h3.h3)
where
    r.end_vid in (select h3index_to_bigint(h3) from tmp_stat_h3 where capacity > 0);

-- set of directed edges from all paths with amount of people travelling on each 
drop table if exists evacuation_estimates;
create table evacuation_estimates as
select
    rs.source,
    rs.target,
    path_start,
    path_end,
    rs.population_in_danger,
    rs.geom,
    rs.cell_capacity,
    rs.total_reachable_capacity,
    rs.population_in_danger * (rs.cell_capacity::float / rs.total_reachable_capacity::float) as estimated_evacuees
from route_segments rs;

-- NOTE: LLM suggested to create intermediate map of people traveling across each cell, not needed for evacuation graph
-- drop TABLE if exists cell_traffic;
-- CREATE  TABLE cell_traffic AS
-- SELECT h3, SUM(estimated_evacuees) AS people_traveling
-- FROM (
--     SELECT source AS h3, estimated_evacuees FROM evacuation_estimates
--     UNION ALL
--     SELECT target AS h3, estimated_evacuees FROM evacuation_estimates
-- ) AS sub
-- GROUP BY h3
-- ORDER BY people_traveling DESC;


-- this is aggregated *undirected* graph of all edges:
-- each edge has a sum of people travelling through it, even if they has different start and/or end points
drop table if exists evac_agg;
create table evac_agg as
select source, target, sum(estimated_evacuees) estimated_evacuees, max(geom) geom
from evacuation_estimates
group by 1,2;


-- This is *directed* evacuation graph
-- In pgr_dijkstra solution, some paths have overlapping edges.
-- Sometimes they're traveled in opposite directions.
-- For final graph select one of 2 possible directions by choosing the edge with greater traffic
drop table if exists evac_agg_directed;
create table evac_agg_directed as
select distinct on (source, target) source, target, estimated_evacuees, geom
from evacuation_estimates e
order by source, target, estimated_evacuees desc;
