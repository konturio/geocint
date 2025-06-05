CREATE OR REPLACE FUNCTION calculate_isodist_h3(
    src_geog     geography,
    max_distance double precision,
    res          int
)
RETURNS TABLE (                       -- <─ names must match what callers expect
    h3        h3index,
    distance  double precision,       --  ← was avg_dist_m
    geom      geometry
)
LANGUAGE sql
STABLE
COST 5000
AS
$func$
WITH
bbox AS (
    SELECT ST_Envelope(ST_Buffer(src_geog, max_distance)::geometry) AS g
),
start_vertex AS (
    SELECT CASE
             WHEN ST_Distance(src_geog,
                              ST_StartPoint(seg_geom)::geography) <
                  ST_Distance(src_geog,
                              ST_EndPoint(seg_geom)::geography)
             THEN node_from ELSE node_to END                AS node_id,
           ST_Distance(src_geog,
                       ST_ClosestPoint(seg_geom, src_geog)::geography)
                                                         AS offset_m
    FROM   osm_road_segments, bbox
    WHERE  seg_geom && g
    ORDER  BY seg_geom <-> src_geog::geometry
    LIMIT  1
),
reachable AS (
    WITH env AS (
        SELECT ST_XMin(g) xmin, ST_YMin(g) ymin,
               ST_XMax(g) xmax, ST_YMax(g) ymax
        FROM   bbox
    )
    SELECT *
    FROM   pgr_drivingdistance(
             format(
'SELECT seg_id  AS id,
        node_from AS source,
        node_to   AS target,
        length    AS cost,
        length    AS reverse_cost
 FROM   osm_road_segments
 WHERE  seg_geom && ST_MakeEnvelope(%L,%L,%L,%L,4326)',
                    (SELECT xmin FROM env),
                    (SELECT ymin FROM env),
                    (SELECT xmax FROM env),
                    (SELECT ymax FROM env)
             ),
             ARRAY[(SELECT node_id FROM start_vertex)],
             max_distance,
             FALSE,   -- directed?
             FALSE    -- equicost OFF  (faster, less RAM)
           )
),
edges AS (
    SELECT CASE WHEN r.node = s.node_from THEN ST_Reverse(s.seg_geom)
                ELSE s.seg_geom END                     AS geom,
           s.length                                     AS edge_len,
           r.agg_cost - s.length + sv.offset_m         AS cost_tail,
           r.agg_cost              + sv.offset_m       AS cost_head
    FROM   reachable r
    JOIN   osm_road_segments s ON s.seg_id = r.edge
    CROSS  JOIN start_vertex sv
    WHERE  r.edge <> -1
),
trimmed AS (
    SELECT CASE WHEN cost_head <= max_distance
                THEN geom
                ELSE ST_LineSubstring(
                       geom, 0,
                       (max_distance - cost_tail) / edge_len) END  AS geom,
           cost_tail
    FROM   edges
    WHERE  cost_tail < max_distance
),
measured AS (
    SELECT ST_AddMeasure(
             geom,
             cost_tail,
             cost_tail + ST_Length(geom::geography))     AS mline
    FROM   trimmed
),
samples AS (
    SELECT
        ST_M(pt)                               AS dist_m,
        h3_lat_lng_to_cell(pt::point, res)     AS hex
    FROM   measured,
           LATERAL ST_DumpPoints(
             ST_Segmentize(
               mline::geography,
               h3_get_hexagon_edge_length_avg(res, 'm')
             )::geometry
           ) AS d(path, pt)
    WHERE  ST_M(pt) <= max_distance
)
SELECT
    hex                         AS h3,
    AVG(dist_m)                 AS distance,   --  ← renamed here
    h3_cell_to_boundary_geometry(hex) AS geom
FROM   samples
GROUP  BY hex;
$func$;