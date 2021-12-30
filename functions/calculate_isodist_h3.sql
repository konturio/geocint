create or replace function calculate_isodist_h3(
    in source         geometry,
    in max_distance   float,
    in split_interval float,
    out h3            h3index,
    out distance      float,
    out geom          geometry
)
    returns setof record
    parallel unsafe
    cost 10000
    language plpgsql
    stable
as
$$
declare
    max_area geometry;
    start_node bigint;
begin
    source = ST_Transform(source, 4326);
    max_area = ST_Buffer(source::geography, max_distance)::geometry;

    select (array [s.node_from, s.node_to])[p.path[1]] node_id
    from (
             select s.node_from, s.node_to, s.seg_geom
             from osm_road_segments s
             where ST_Intersects(s.seg_geom, ST_Buffer(source::geography, split_interval)::geometry)
             order by source <-> s.seg_geom
             limit 1
         ) s,
         ST_DumpPoints(s.seg_geom) p
    order by source <-> p.geom
    limit 1
    into start_node;

    exit when start_node is null;

    return query
        with segments as (
            select s.seg_id, s.node_from, s.node_to, s.length, s.seg_geom
            from osm_road_segments s
            where ST_Intersects(s.seg_geom, max_area)
              and drive_time is not null
        ),
             driving_distance as (
                 select d.node,
                        d.edge,
                        d.agg_cost
                 from pgr_drivingdistance(
                              'select seg_id as id, ' ||
                                  '       node_from as source, ' ||
                                  '       node_to as target, ' ||
                                  '       length as cost, ' ||
                                  '       length as reverse_cost ' ||
                                  'from osm_road_segments ' ||
                                  'where ST_Intersects(seg_geom, ''' || max_area::text || '''::geometry) ' ||
                                  'and drive_time is not null;',
                              array [start_node],
                              max_distance,
                              false,
                              true
                          ) d
             ),
             spanning_tree as (
                 select s.seg_id,
                        s.node_from,
                        s.node_to,
                        s.length,
                        ST_MakeLine(
                                ST_Force3D(
                                        ST_StartPoint(s.seg_geom),
                                        case
                                            when d.node = s.node_from
                                                then d.agg_cost
                                            else d.agg_cost - s.length
                                        end
                                    ),
                                ST_Force3D(
                                        ST_EndPoint(s.seg_geom),
                                        case
                                            when d.node = s.node_from
                                                then d.agg_cost - s.length
                                            else d.agg_cost
                                        end
                                    )
                            ) geom
                 from driving_distance d,
                      segments s
                 where d.edge = s.seg_id
                 union all
                 select s.seg_id,
                        s.node_from,
                        s.node_to,
                        s.length,
                        ST_MakeLine(
                                ST_Force3D(
                                        case
                                            when d2.node = s.node_from or d3.node = s.node_to
                                                then
                                                ST_StartPoint(s.seg_geom)
                                            when d2.node = s.node_to or d3.node = s.node_from
                                                then
                                                ST_EndPoint(s.seg_geom)
                                        end,
                                        coalesce(d2.agg_cost, d3.agg_cost + s.length)
                                    ),
                                ST_Force3D(
                                        case
                                            when d3.node = s.node_from or d2.node = s.node_to
                                                then
                                                ST_StartPoint(s.seg_geom)
                                            when d3.node = s.node_to or d2.node = s.node_from
                                                then
                                                ST_EndPoint(s.seg_geom)
                                        end,
                                        coalesce(d3.agg_cost, d2.agg_cost + s.length)
                                    )
                            ) geom
                 from segments s
                      left join driving_distance d1
                         on s.seg_id = d1.edge
                      left join driving_distance d2
                         on s.node_from = d2.node
                      left join driving_distance d3
                         on s.node_to = d3.node
                 where d1.edge is null
                   and coalesce(d2.edge, d3.edge) is not null
             ),
             points as (
                 select distinct (ST_DumpPoints(t.geom)).geom
                 from spanning_tree t
             ),
             delaunay_triangles as (
                 select (ST_Dump(ST_ConstrainedDelaunayTriangles(ST_Collect(d.geom)))).geom
                 from points d
             ),
             delaunay_minmax as (
                 select d.geom, ST_ZMin(d.geom) "min", ST_ZMax(d.geom) max
                 from delaunay_triangles d
             ),
             isodist as (
                 select i * split_interval distance, ST_CollectionExtract(ST_Union(d.geom), 3) geom
                 from generate_series(1, ceil(max_distance / split_interval)::integer) i
                      cross join lateral (
                     select ST_LocateBetweenElevations(
                                    t.geom,
                                    (i - 1) * split_interval,
                                    i * split_interval
                                ) geom
                     from delaunay_minmax t
                     where min <= i * split_interval
                       and max >= (i - 1) * split_interval
                     ) d
                 group by i
             )
        select h.h3, d.distance, h3_to_geo_boundary_geometry(h.h3)
        from (
                 select h3_polyfill(ST_Union(i.geom), 8) h3
                 from isodist i
             ) h
             cross join lateral (
            select i.distance
            from h3_to_geo_boundary_geometry(h.h3) h3geom,
                 isodist i
            where ST_Intersects(i.geom, h3geom)
            order by ST_Area(ST_Intersection(i.geom, h3geom)) desc
            limit 1
            ) d;
end;
$$;
