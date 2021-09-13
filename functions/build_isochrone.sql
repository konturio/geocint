create or replace function build_isochrone(
    source geometry, -- source point
    max_speed float, -- maximum speed in kmph
    time_limit float, -- limit in minutes
    profile text, -- OSRM profile
    isochrone_interval float = null -- if not null - split isochrone by the interval in minutes
)
    returns table
            (
                minute float,
                geom   geometry
            )
    parallel safe
    cost 10000
    language plpgsql
as
$$
declare
    start_node   bigint;
    start_point  geometry;
    max_distance float;
    max_area     geometry;
begin
    -- convert to seconds
    isochrone_interval = coalesce(isochrone_interval, time_limit) * 60;

    -- convert speed to mps and time to seconds
    max_distance = max_speed / 3.6 * time_limit * 60;

    -- calculate the maximum possible area
    max_area = ST_Buffer(ST_PointOnSurface(source)::geography, max_distance)::geometry;

    -- choose id and geom of the nearest node in roads
    select (array [node_from, node_to])[p.path[1]], p.geom
    from (select *
          from osm_road_segments
          where ST_Intersects(seg_geom, max_area)
          order by source <-> seg_geom
         ) s,
         ST_DumpPoints(s.seg_geom) p
    order by source <-> p.geom
    limit 1
    into start_node, start_point;

    return query
        with tree as materialized (
            select *
            from osm_road_segments
            where ST_Intersects(seg_geom, max_area)
        ),
             driving_distance as (
                 select d.node, s.seg_id, s.node_from, s.node_to, s.seg_geom
                 from pgr_drivingdistance('select seg_id as id, ' ||
                                          '       node_from as source, ' ||
                                          '       node_to as target, ' ||
                                          '       length as cost, ' ||
                                          '       length as reverse_cost' ||
                                          ' from osm_road_segments' ||
                                          ' where ' ||
                                          ' ST_Intersects(seg_geom, ''' || max_area::text ||
                                          '''::geometry)',
                                          array [start_node]::bigint[],
                                          max_distance,
                                          false,
                                          true
                          ) d,
                      osm_road_segments s
                 where d.edge = s.seg_id
             ),
             osrm_table as (
                 select unnest(array_agg(id)) "node_id",
                        osrm_table(
                                start_point,
                                array_agg(node.geom),
                                profile
                            )                 "eta"
                 from (
                          select distinct (array [node_from, node_to])[p.path[1]] "id", -- get node_id using dump.path
                                          p.geom
                          from driving_distance d,
                               ST_DumpPoints(d.seg_geom) p
                      ) node
             ),
             time_annotated_tree as (
                 select tree.seg_id,
                        ST_SetSRID(
                                ST_MakeLine(
                                        ST_MakePoint(ST_X(point_from), ST_Y(point_from), t1.eta),
                                        ST_MakePoint(ST_X(point_to), ST_Y(point_to), t2.eta)
                                    ),
                                4326
                            ) "geom"
                 from tree,
                      osrm_table t1,
                      osrm_table t2,
                      lateral (VALUES (ST_StartPoint(tree.seg_geom), ST_EndPoint(tree.seg_geom))) as v(point_from, point_to)
                 where tree.node_from = t1.node_id
                   and tree.node_to = t2.node_id
             ),
             delaunay_triangles as (
                 select (ST_Dump(ST_ConstrainedDelaunayTriangles(ST_Collect(points.geom)))).geom
                 from (
                          select distinct on (ST_Force2D(t.geom)) t.geom "geom"
                          from time_annotated_tree t
                      ) points
             ),
             delaunay_minmax as (
                 select d.geom, ST_ZMin(d.geom) "min", ST_ZMax(d.geom) "max"
                 from delaunay_triangles d
             )
        select (num * isochrone_interval) / 60,
               ST_MakeValid(
                       ST_ChaikinSmoothing(
                               ST_CollectionExtract(
                                       ST_Union(
                                               ST_ConvexHull(
                                                       ST_LocateBetweenElevations(
                                                               ST_Boundary(d.geom),
                                                               (num - 1) * isochrone_interval,
                                                               num * isochrone_interval
                                                           )
                                                   )
                                           ),
                                       3
                                   )
                           )
                   ) "geom"
        from generate_series(1, ceil(time_limit * 60 / isochrone_interval)::integer) num,
             lateral (
                 select t.geom
                 from delaunay_minmax t
                 where min <= num * isochrone_interval
                   and max >= (num - 1) * isochrone_interval
                 ) d
        group by 1;
end;
$$;
