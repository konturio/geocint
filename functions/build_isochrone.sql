create or replace function build_isochrone(
    source geometry, -- source point
    max_speed float, -- maximum speed in kmph
    time_limit float, -- limit in minutes
    profile text, -- OSRM profile
    isochrone_interval float = null, -- if not null - split isochrone by the interval in minutes
    reversed boolean = false -- calculate reversed routes
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
    time_limit = time_limit * 60;
    isochrone_interval = coalesce(isochrone_interval * 60, time_limit);

    -- convert speed to mps and time to seconds
    max_distance = max_speed / 3.6 * time_limit;

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
        -- get road segments in max_area
        with segments as materialized (
            select *
            from osm_road_segments s
            where ST_Intersects(seg_geom, max_area)
        ),
             -- extract spanning tree with distances less then max_distance
             driving_distance as (
                 select d.node, s.seg_id, s.node_from, s.node_to, s.seg_geom
                 from pgr_drivingdistance('select seg_id as id, ' ||
                                          '       node_from as source, ' ||
                                          '       node_to as target, ' ||
                                          '       length as cost, ' ||
                                          '       length as reverse_cost' ||
                                          ' from osm_road_segments' ||
                                          ' where ' ||
                                          ' ST_Intersects(seg_geom, ''' ||
                                          max_area::text ||
                                          '''::geometry)',
                                          array [start_node]::bigint[],
                                          max_distance,
                                          false,
                                          true
                          ) d,
                      osm_road_segments s
                 where d.edge = s.seg_id
             ),
             -- build spanning tree with extra edges
             spanning_tree as (
                 select seg_id, node_from, node_to, seg_geom
                 from driving_distance
                 union all
                 select t.seg_id, t.node_from, t.node_to, t.seg_geom
                 from segments t
                          left join driving_distance d1
                                    on d1.seg_id = t.seg_id
                          left join driving_distance d2
                                    on t.node_from = d2.node
                          left join driving_distance d3
                                    on t.node_to = d3.node
                 where d1.seg_id is null
                   and coalesce(d2.seg_id, d3.seg_id) is not null
             ),
             -- extract nodes from spanning tree
             nodes as (
                 select distinct (array [node_from, node_to])[p.path[1]] "node_id",
                                 p.geom
                 from spanning_tree,
                      ST_DumpPoints(seg_geom) p
             ),
             -- calculate ETAs using OSRM tables
             etas as (
                 select coalesce(o1.eta, o2.eta) "eta", coalesce(o1.finish, o2.start) "geom"
                 from (
                          select array [start_point] "sources",
                                 array_agg(p.geom)   "destinations"
                          from nodes p
                      ) p
                          left join osrm_table_etas(sources, destinations, profile) o1
                                    on (not reversed)
                          left join osrm_table_etas(destinations, sources, profile) o2
                                    on (reversed)
             ),
             -- build a Constrained Delaunay triangulation around the nodes
             delaunay_triangles as (
                 select (ST_Dump(ST_ConstrainedDelaunayTriangles(ST_Collect(ST_PointZ(ST_X(point), ST_Y(point), eta, 3857))))).geom
                 from etas e,
                      ST_Transform(e.geom, 3857) "point"
             ),
             -- extract min and max ETA from triangles
             delaunay_minmax as (
                 select d.geom, ST_ZMin(d.geom) "min", ST_ZMax(d.geom) "max"
                 from delaunay_triangles d
             )
        -- build isochrone
        select num * isochrone_interval / 60 "minutes",
               ST_ChaikinSmoothing(
                       ST_CollectionExtract(
                               ST_Union(
                                       ST_LocateBetweenElevations(
                                               d.geom,
                                               (num - 1) * isochrone_interval,
                                               num * isochrone_interval
                                           )
                                   ),
                               3
                           )
                   )                         "geom"
        from generate_series(1, ceil(time_limit / isochrone_interval)::integer) num,
             lateral (
                 select t.geom
                 from delaunay_minmax t
                 where min <= num * isochrone_interval
                   and max >= (num - 1) * isochrone_interval
                 ) d
        group by 1;
end;
$$;
