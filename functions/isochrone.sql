-- TODO: convert into function
drop table if exists pgrouting_routed_distance;
create table pgrouting_routed_distance as (
  with params as (
    select
      -- malino_hs:
      --'SRID=4326;POINT(27.4781235 53.8730107)'::geometry as geom,
      -- home:
      'SRID=4326;POINT(27.6502915 53.8690124)'::geometry as geom,
      -- PDC:
      --'SRID=4326;POINT(-156.4377840 20.7506470)'::geometry as geom,
      1.4                                                as max_speed,
      30 * 60                                            as time_limit
    ),
    graph_bounds as (
      select
        ST_Buffer(geom::geography, time_limit * max_speed)::geometry as possible_area,
        (
          select
            node_from
          from
            osm_road_segments
          order by geom <-> seg_geom
          limit 1
        )                                                            as start_node_id,
        1.01 * time_limit                                            as time_limit
      from
        params
      ),
    time_annotated_spanning_tree as (
      select distinct on (node_from, node_to)
        -- FIXME: why are there duplicates?
        ST_SetSRID(
            ST_MakeLine(
                ST_MakePoint(
                    ST_X(ST_StartPoint(z.seg_geom)),
                    ST_Y(ST_StartPoint(z.seg_geom)),
                    agg_cost
                  ),
                ST_MakePoint(
                    ST_X(ST_EndPoint(z.seg_geom)),
                    ST_Y(ST_EndPoint(z.seg_geom)),
                    agg_cost + walk_time
                  )
              ),
            4326
          ) as geom
      from
        graph_bounds
          join lateral (
          select distinct on (edge, node)
            -- FIXME: why are there duplicates?
            edge,
            node,
            agg_cost
          from
            pgr_drivingDistance(
                  'select osm_id as id, node_from as source, node_to as target, walk_time/2.324 as cost, walk_time/2.324 as reverse_cost' ||
                  ' from osm_road_segments where walk_time is not null and ST_Intersects(seg_geom, ''' ||
                  ST_AsEWKT(possible_area) || ''')',
                  start_node_id,
                  time_limit
              ) d
          order by 1, 2, 3
          ) d on true
          join osm_road_segments z on (z.osm_id = d.edge and (z.node_to = d.node or z.node_from = d.node))
      order by
        node_from,
        node_to,
        agg_cost
      ),
    densified_temporal_mesh as (
      -- TODO: look at visibility (after building first mesh?)
      -- TODO: lower complexity (O(N^2) currently)
      -- TODO: building levels: 15 s per level on foot, 40s constant going on level, 30s wait for elevator, 10s per level on elevator
      select
        ST_Union(
            ST_SetSRID(
                ST_MakePoint(
                    ST_X(t.geom),
                    ST_Y(t.geom),
                    ST_Z(cp.geom) +
                    ST_Distance(cp.geom::geography, t.geom::geography) * 1 -- FIXME: 1 m/s for where no roads
                  ),
                4326
              ),
            (select ST_Collect(geom) from time_annotated_spanning_tree)
          )     as geom,
        cp.geom as cp_geom
      from
        (select count(*) as count, ST_ConvexHull(ST_Collect(geom)) as hull from time_annotated_spanning_tree) z,
        lateral (select (ST_Dump(ST_GeneratePoints(hull, count))).geom ) t,
        lateral (
          select
            ST_Transform(ST_ClosestPointWithZ(ST_Transform(tast.geom, 3857), ST_Transform(t.geom, 3857)), 4326) as geom
          from
            time_annotated_spanning_tree tast
          order by ST_Transform(tast.geom, 3857) <-> ST_Transform(t.geom, 3857)
          limit 1
          ) cp
      ),
    delaunay_triangles as (
      -- TODO: convert to TIN in PostGIS 3
      -- TODO: use Constrained Delaunay in PostGIS 3
      select
        ST_ZMin(geom) as tmin,
        ST_ZMax(geom) as tmax,
        geom
      from
        (
          select
            -- using GEOS:
            --(ST_Dump(ST_DelaunayTriangles(ST_Segmentize(ST_Transform(ST_Collect(geom), 3857), 50)))).geom

            -- using SFCGAL and densified mesh
            -- (ST_Dump(ST_Triangulate2DZ(ST_UnaryUnion(ST_Transform(ST_Collect(geom), 3857))))).geom

            -- using SFCGAL and not densified mesh
            --  TODO: Teach ST_Node to handle GEOMETRYCOLLECTION(POINT, LINE)
            (ST_Dump(ST_Triangulate2DZ(ST_Node(ST_Transform(ST_Collect(geom), 3857))))).geom
          from
            -- in squarish city:
            time_annotated_spanning_tree
          -- In fieldish area:
          --densified_temporal_mesh
        ) as z
      ),
    isochrones as (
      -- TODO: use direct TIN clipping in PostGIS 3
      select
        -- TODO: option to switch off smoothing
        ST_ChaikinSmoothing(
            ST_CollectionExtract(
                ST_Union(
                    ST_ConvexHull(
                        ST_LocateBetweenElevations(
                            ST_Boundary(t.geom),
                            (minute - 1) * 60,
                            minute * 60
                          )
                      )
                  ),
                3
              )
          ) as geom,
        minute
      from
        params,
        -- TODO: dynamic cut range decision
        generate_series(1, ceil(params.time_limit / 60)::integer) minute
          join delaunay_triangles t on (tmin <= minute * 60 and tmax >= (minute - 1) * 60)
      group by minute
      )
    select * from isochrones
);