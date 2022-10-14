create or replace function calculate_isodist_h3(
    in source       geometry,
    in max_distance double precision,
    in resolution   integer,
    out h3          h3index,
    out distance    double precision,
    out geom        geometry
) returns setof record
    stable
    cost 10000
    language plpgsql
as
$$
declare
    max_area geometry;
    start_node bigint;
    start_distance double precision;
begin
    source = ST_Transform(source, 4326);
    max_area = ST_Buffer(source::geography, max_distance)::geometry;

    select (array [s.node_from, s.node_to])[p.path[1]] node_id,
           ST_Distance(source::geography, p.geom::geography)
    from (
             select s.node_from, s.node_to, s.seg_geom
             from osm_road_segments s
             where ST_Intersects(s.seg_geom, max_area)
             order by source <-> s.seg_geom
             limit 1
         ) s,
         ST_DumpPoints(s.seg_geom) p
    order by source <-> p.geom
    limit 1
    into start_node, start_distance;

    if start_node is null then
        return ;
    end if;

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
                        d.agg_cost + start_distance agg_cost
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
             )
        select hex, avg(ST_Z(p.geom)), h3_cell_to_boundary(hex)::geometry
        from spanning_tree s,
             ST_DumpPoints(ST_Segmentize(
                     s.geom::geography,
                     h3_get_hexagon_edge_length_avg(resolution, 'm')
                 )::geometry) p,
             h3_lat_lng_to_cell(p.geom::point, resolution) hex
        where ST_Z(p.geom) <= max_distance
        group by hex;
end;
$$;