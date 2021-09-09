create or replace function calculate_etas(
    geom geometry,
    avg_speed float,
    "time" float
)
    returns table
            (
                node bigint,
                eta  float
            )
    stable
    cost 10000
    language plpgsql
as
$$
declare
    start_node        bigint;
    start_point       geometry;
    max_distance      float;
    max_area          geometry;
    end_node          bigint;
    end_point         geometry;
    visited_nodes     bigint[];
    cur_visited_nodes bigint[];
    etas              float[];
begin
    max_distance = avg_speed / 3.6 * time * 60;
    start_point = ST_Centroid(geom);
    max_area = ST_Buffer(start_point::geography, max_distance)::geometry;
    start_node = (
        select node_from
        from osm_road_segments
        where ST_Intersects(seg_geom, max_area)
        order by start_point <-> seg_geom
        limit 1
    );
    visited_nodes = '{}';
    for end_node, end_point in
        with driving_distance as (
            select d.node,
                   d.agg_cost,
                   s.seg_id,
                   s.node_from,
                   s.node_to,
                   case
                       when d.node = s.node_from then ST_StartPoint(s.seg_geom)
                       else ST_EndPoint(s.seg_geom)
                       end "geom"
            from pgr_drivingDistance(
                                                             'select seg_id as id, ' ||
                                                             '       node_from as source, ' ||
                                                             '       node_to as target, ' ||
                                                             '       length as cost, ' ||
                                                             '       length as reverse_cost' ||
                                                             ' from public.osm_road_segments' ||
                                                             ' where length is not null and ' ||
                                                             ' ST_Intersects(seg_geom, ''' ||
                                                             max_area::text ||
                                                             '''::geometry)',
                                                             array [start_node]::bigint[],
                                                             max_distance,
                                                             false,
                                                             true
                     ) d,
                 public.osm_road_segments s
            where d.edge = s.seg_id
        ),
             data as (
                 select d.node, d.agg_cost, d.geom
                 from driving_distance d
                 order by agg_cost desc
             )
        select distinct d.node, d.geom
        from data d
        loop
            continue when end_node = any (visited_nodes);
            with t as (
                select n.node::bigint, sum(d.duration::float) over (order by n.idx) AS agg_duration
                from http_get('http://localhost:5000/route/v1/bicycle/' ||
                              ST_X(start_point) || ',' || ST_Y(start_point) || ';' ||
                              ST_X(end_point) || ',' || ST_Y(end_point) ||
                              '?steps=false&annotations=nodes&annotations=duration&alternatives=false&overview=false') r,
                     cast(r as jsonb) j,
                     jsonb_array_elements((j -> 'routes' -> 0 -> 'legs' -> 0 -> 'annotation' -> 'nodes') - 0)
                         with ordinality as n("node", "idx"),
                     jsonb_array_elements(j -> 'routes' -> 0 -> 'legs' -> 0 -> 'annotation' -> 'duration')
                         with ordinality as d("duration", "idx")
                where n.idx = d.idx
            )
            select array_agg(t.node),
                   array_agg(agg_duration)
            from t
            where t.node != all (visited_nodes)
            into cur_visited_nodes, etas;

            return query
                select u.node, u.eta
                from unnest(cur_visited_nodes, etas) u(node, eta)
                where u.eta < time * 60;
            visited_nodes = visited_nodes || cur_visited_nodes;
        end loop;
    return;
end;
$$;
