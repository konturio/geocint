create or replace function calculate_etas(
    geom geometry, -- start geometry
    avg_speed double precision, -- average speed (kilometers per hour)
    "time" double precision, -- time in minutes
    profile text -- OSRM profile
)
    returns table
            (
                node bigint,
                eta  double precision
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
    end_nodes         bigint[];
    end_point         geometry;
    visited_nodes     bigint[];
    cur_visited_nodes bigint[];
    etas              float[];
begin
    start_point = ST_Centroid(geom);
    max_distance = avg_speed / 3.6 * time * 60; -- convert speed to mps and time to seconds
    max_area = ST_Buffer(start_point::geography, max_distance)::geometry;
    -- choose id of nearest node in roads
    start_node = (
        select node_from
        from osm_road_segments
        where ST_Intersects(seg_geom, max_area)
        order by start_point <-> seg_geom
        limit 1
    );
    visited_nodes = '{}';
    for end_nodes, end_point in
        -- select all nodes in max_area using pgrouting
        select array_agg(d.node),
               case
                   when d.node = s.node_to then ST_StartPoint(s.seg_geom)
                   else ST_EndPoint(s.seg_geom)
                   end "geom",
               min(agg_cost)
        from pgr_drivingDistance(
                     'select seg_id as id, ' ||
                     '       node_from as source, ' ||
                     '       node_to as target, ' ||
                     '       length as cost, ' ||
                     '       length as reverse_cost' ||
                     ' from osm_road_segments' ||
                     ' where length is not null and ' ||
                     ' ST_Intersects(seg_geom, ''' || max_area::text ||
                     '''::geometry)',
                     array [start_node]::bigint[],
                     max_distance,
                     false,
                     true
                 ) d,
             osm_road_segments s
        where d.edge = s.seg_id
          and ST_Intersects(s.seg_geom, max_area)
        group by 2
        having count(*) > 1
        order by 3 desc
        loop
            continue when visited_nodes @> end_nodes;
            -- send requests to OSRM
            with etas as (
                select row_number() over () "id",
                       jsonb_array_elements((r::jsonb -> 'routes' -> 0 -> 'legs' -> 0 -> 'annotation' -> 'nodes') - 0)::bigint "node", -- exclude first node
                       jsonb_array_elements(r::jsonb -> 'routes' -> 0 -> 'legs' -> 0 -> 'annotation' -> 'duration')::float     "duration"
                from http_get('http://localhost:5000/route/v1/' || profile || '/' ||
                              ST_X(start_point) || ',' || ST_Y(start_point) || ';' ||
                              ST_X(end_point) || ',' || ST_Y(end_point) ||
                              '?steps=false&annotations=nodes&annotations=duration&alternatives=false&overview=false'
                         ) r
            ),
                 etas_sum as (
                     select etas.node, sum(duration) over (order by id) "agg_duration"
                     from etas
                 )
            select array_agg(etas_sum.node),
                   array_agg(agg_duration)
            from etas_sum
            where etas_sum.node != all (visited_nodes)
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

alter function calculate_etas(geometry, double precision, double precision, text) owner to gis;
