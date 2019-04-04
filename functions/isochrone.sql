-- TODO: convert into function
drop table if exists pgrouting_isochrones;
create table pgrouting_isochrones as (

  --  drop table if exists pgrouting_routed_distance;
  --create table pgrouting_routed_distance as (
  with params as (
    select
      array [
        -- iDigital
        -- 'SRID=4326;POINT(34.7956953 32.1120321)'::geometry,'SRID=4326;POINT(34.7866363 32.0731404)'::geometry,'SRID=4326;POINT(34.7753630 32.0753070)'::geometry,'SRID=4326;POINT(34.7920503 32.0749544)'::geometry
        --- AMPM tel aviv
        'SRID=4326;POINT(34.7819248 32.072704)'::geometry,'SRID=4326;POINT(34.7816715 32.0851616)'::geometry,'SRID=4326;POINT(34.7823172 32.0881967)'::geometry,'SRID=4326;POINT(34.7694751 32.063592)'::geometry,'SRID=4326;POINT(34.773462 32.062006)'::geometry,'SRID=4326;POINT(34.7717385 32.0758874)'::geometry,'SRID=4326;POINT(34.774692 32.092469)'::geometry,'SRID=4326;POINT(34.768105 32.076168)'::geometry,'SRID=4326;POINT(34.769463 32.0795163)'::geometry,'SRID=4326;POINT(34.7976328 32.1067048)'::geometry,'SRID=4326;POINT(34.774945 32.086936)'::geometry,'SRID=4326;POINT(34.7737857 32.081792)'::geometry,'SRID=4326;POINT(34.7925187 32.1120161)'::geometry,'SRID=4326;POINT(34.7756768 32.0613096)'::geometry,'SRID=4326;POINT(34.770839 32.0547604)'::geometry,'SRID=4326;POINT(34.8239567 32.118174)'::geometry,'SRID=4326;POINT(34.7682964 32.0571749)'::geometry,'SRID=4326;POINT(34.7756676 32.059336)'::geometry,'SRID=4326;POINT(34.7886682 32.0649984)'::geometry,'SRID=4326;POINT(34.7818172 32.0669244)'::geometry,'SRID=4326;POINT(34.7726159 32.0609173)'::geometry,'SRID=4326;POINT(34.7968118 32.0749599)'::geometry,'SRID=4326;POINT(34.7799103 32.0613171)'::geometry,'SRID=4326;POINT(34.768823 32.0727846)'::geometry,'SRID=4326;POINT(34.7734872 32.0719065)'::geometry,'SRID=4326;POINT(34.777729 32.077346)'::geometry,'SRID=4326;POINT(34.7900903 32.070041)'::geometry,'SRID=4326;POINT(34.7595018 32.0550083)'::geometry,'SRID=4326;POINT(34.7912014 32.0778188)'::geometry,'SRID=4326;POINT(34.7728342 32.0692713)'::geometry,'SRID=4326;POINT(34.7774178 32.0683439)'::geometry,'SRID=4326;POINT(34.8329508 32.1095728)'::geometry,'SRID=4326;POINT(34.9024311 32.1628052)'::geometry,'SRID=4326;POINT(34.8166936 32.0838966)'::geometry,'SRID=4326;POINT(34.8095539 32.0845254)'::geometry,'SRID=4326;POINT(34.814445 32.088366)'::geometry,'SRID=4326;POINT(34.7387508 32.0145361)'::geometry,'SRID=4326;POINT(34.801327 31.932111)'::geometry,'SRID=4326;POINT(34.8398751 32.1669801)'::geometry,'SRID=4326;POINT(34.811293 32.1805457)'::geometry,'SRID=4326;POINT(34.861785888671875 32.06633758544922)'::geometry,'SRID=4326;POINT(34.8155075 32.0766751)'::geometry,'SRID=4326;POINT(34.8015427 32.0748622)'::geometry
        --         -- malino_hs:
        --         'SRID=4326;POINT(27.4781235 53.8730107)'::geometry,
        --         -- green_hs
        --         'SRID=4326;POINT(27.5977138 53.9430294)'::geometry,
        --         -- eventspace
        --         'SRID=4326;POINT(27.5692916 53.8901468)'::geometry
        ]::geometry[] as geom,
      -- PDC:
      --'SRID=4326;POINT(-156.4377840 20.7506470)'::geometry as geom,
      1.4             as max_speed,
      60 * 60         as time_limit,
      3000            as extra_radius,
      5 * 60          as isochrone_interval
    ),
    graph_bounds as (
      select
        ST_Buffer(ST_Collect(geom)::geography,
                  greatest(time_limit * max_speed, extra_radius))::geometry as possible_area,
        (
          select
            array_agg(node_from)
          from
            unnest(geom) as single_geom,
            lateral (
              select
                node_from
              from
                osm_road_segments
              where
                walk_time is not null
              order by single_geom <-> seg_geom
              limit 1
              ) z
        )                                                                   as start_node_id,
        -- we need 2x to map out all "go away and return" paths.
        --  greatest(2 * time_limit, extra_radius / max_speed)                  as time_limit
        1.1 * time_limit                                                    as time_limit
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
          )                     as geom,

        ST_Centroid(z.seg_geom) as start_point,
        from_v
      from
        graph_bounds
          join lateral (
          select distinct on (edge, node)
            -- FIXME: why are there duplicates?
            edge,
            node,
            agg_cost,
            from_v
          from
            pgr_drivingDistance(
                  'select seg_id as id, node_from as source, node_to as target, walk_time as cost, walk_time as reverse_cost' ||
                  ' from osm_road_segments where walk_time is not null and ST_Intersects(seg_geom, ''' ||
                  ST_AsEWKT(possible_area) || ''')',
                  start_node_id,
                  time_limit,
                  false,
                  true
              ) d
          order by 1, 2, 3
          ) d on true
          join osm_road_segments z on (z.seg_id = d.edge and (z.node_to = d.node or z.node_from = d.node))
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
            (ST_Dump(ST_DelaunayTriangles(ST_Segmentize(ST_Transform(ST_Collect(geom), 3857), 50)))).geom

            -- using SFCGAL and densified mesh
            --(ST_Dump(ST_Triangulate2DZ(ST_UnaryUnion(ST_Transform(ST_Collect(geom), 3857))))).geom

            -- using SFCGAL and not densified mesh
            --  TODO: Teach ST_Node to handle GEOMETRYCOLLECTION(POINT, LINE)
            --(ST_Dump(ST_Triangulate2DZ(ST_Node(ST_Transform(ST_Collect(geom), 3857))))).geom
          from
            -- in squarish city:
            time_annotated_spanning_tree
          -- In fieldish area:
          --densified_temporal_mesh
        ) as z
      where
        ST_Perimeter(geom) < 3000
      ),
    isochrones as (
      -- TODO: use direct TIN clipping in PostGIS 3
      select
        (isochrone_number * isochrone_interval) / 60 as minute,
        -- TODO: option to switch off smoothing
        ST_ChaikinSmoothing(
            ST_CollectionExtract(
                ST_Union(
                    ST_ConvexHull(
                        ST_LocateBetweenElevations(
                            ST_Boundary(t.geom),
                            (isochrone_number - 1) * isochrone_interval,
                            isochrone_number * isochrone_interval
                          )
                      )
                  ),
                3
              )
          )                                          as geom

      from
        params,
        -- TODO: dynamic cut range decision
        generate_series(1, ceil(params.time_limit / isochrone_interval)::integer) isochrone_number
          join lateral ( select *
                         from
                           delaunay_triangles
                         where
                           tmin <= isochrone_number * isochrone_interval
                           and tmax >= (isochrone_number - 1) * isochrone_interval
          ) t on true
      group by 1
      ),
    closest_voronoi as (
      select
        ST_Buffer(ST_Collect(p.geom), 0),
        from_v
      from
        (
          select
            (ST_Dump(ST_VoronoiPolygons(ST_Collect(start_point)))).geom as geom
          from
            time_annotated_spanning_tree
        ) p,
        (select from_v, ST_Collect(start_point) as geom from time_annotated_spanning_tree t group by from_v) v
      where
        ST_Intersects(p.geom, v.geom)
      group by from_v
      )
    select *
    from
      isochrones
  --closest_voronoi
);