---------------------------------------------------------------------------
-- calculate_isodist_h3  –  iso-distance surface binned to H3
---------------------------------------------------------------------------
create or replace function calculate_isodist_h3(
    src_geog     geography,        -- start point (EPSG-4326)
    max_distance double precision, -- metres along roads
    res          int               -- H3 resolution
)
returns table (
    h3          h3index,
    avg_dist_m  double precision,
    geom        geometry
)
language sql
stable
cost 5000
as
$func$
with
bbox as (
    select ST_Envelope(ST_Buffer(src_geog, max_distance)::geometry) as g
),
start_vertex as (
    select case
               when ST_Distance(src_geog,
                              ST_StartPoint(seg_geom)::geography) <
                    ST_Distance(src_geog,
                              ST_endPoint(seg_geom)::geography)
               then node_from else node_to end              as node_id,
           ST_Distance(src_geog,
                       ST_ClosestPoint(seg_geom, src_geog)::geography)
                                                         as offset_m
    from   osm_road_segments, bbox
    where  seg_geom && g
    order by seg_geom <-> src_geog::geometry
    limit 1
),
reachable as (
    with env as (
        select ST_XMin(g) xmin, ST_YMin(g) ymin,
               ST_XMax(g) xmax, ST_YMax(g) ymax
        from   bbox
    )
    select *
    from   pgr_drivingdistance(
             format(
'select seg_id  as id,
        node_from as source,
        node_to   as target,
        length    as cost,
        length    as reverse_cost
 from   osm_road_segments
 where  seg_geom && ST_MakeEnvelope(%L,%L,%L,%L,4326)',
                    (select xmin from env),
                    (select ymin from env),
                    (select xmax from env),
                    (select ymax from env)
             ),
             ARRAY[(select node_id from start_vertex)],
             max_distance,
             FALSE,   -- directed?
             FALSE    -- equicost OFF
           )
),
edges as (
    select CASE WHEN r.node = s.node_from THEN ST_Reverse(s.seg_geom)
                ELSE s.seg_geom end                    as geom,
           s.length                                    as edge_len,
           r.agg_cost - s.length + sv.offset_m         as cost_tail,
           r.agg_cost              + sv.offset_m       as cost_head
    from  reachable r
    join  osm_road_segments s on s.seg_id = r.edge
    cross join start_vertex sv
    where r.edge <> -1
),
trimmed as (
    select CASE WHEN cost_head <= max_distance
                THEN geom
                ELSE ST_LineSubstring(
                       geom, 0,
                       (max_distance - cost_tail) / edge_len) end  as geom,
           cost_tail
    from   edges
    where  cost_tail < max_distance
),
measured as (
    select ST_AddMeasure(
             geom,
             cost_tail,
             cost_tail + ST_Length(geom::geography))     as mline
    from   trimmed
),
samples as (
    select
        ST_M(pt)                               as dist_m,
        h3_lat_lng_to_cell(pt::point, res)     as hex
    from   measured,
           LATERAL ST_DumpPoints(
             ST_Segmentize(
               mline::geography,
               h3_get_hexagon_edge_length_avg(res, 'm')
             )::geometry
           ) as d(path, pt)                    -- two columns only
    where  ST_M(pt) <= max_distance
)
select
    hex                                as h3,
    avg(dist_m)                        as avg_dist_m,
    h3_cell_to_boundary_geometry(hex)  as geom
from   samples
group by hex;
$func$;
