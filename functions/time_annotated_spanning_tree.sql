CREATE OR REPLACE FUNCTION time_annotated_spanning_tree(IN inner_geom geometry) 
RETURNS TABLE(
	geom geometry
)
AS 
$body$
	DECLARE
	max_speed integer := 1.4;
	time_limit integer := 2*60*60;
	extra_radius integer := 3000;
	isochrone_interval integer := 5*60;
	possible_area geometry;
	start_node_id bigint;
	BEGIN
		possible_area = ST_Buffer(ST_Collect(inner_geom)::geography, greatest(time_limit * max_speed, extra_radius))::geometry;
		select into start_node_id node_from
      from
        osm_road_segments
      where
        walk_time is not null
      order by inner_geom <-> seg_geom
      limit 1;
		time_limit = 1.1 * time_limit;
		RETURN QUERY
		with drivingDistance as (
			select * from
			  lateral (
			    select distinct on (edge, node)
			      edge,
            node,
            agg_cost
          from
            pgr_drivingDistance(
              'select seg_id as id, node_from as source, node_to as target, walk_time as cost, walk_time as reverse_cost' ||
              ' from osm_road_segments where walk_time is not null and ST_Intersects(seg_geom, ''' ||
              ST_AsEWKT(possible_area) || '''::geometry)',
              ARRAY[start_node_id]::bigint[],
              time_limit,
              false,
              true
            ) d
          order by 1, 2, 3
        ) d
			  join osm_road_segments z on z.seg_id = d.edge
		)
		select g.geom from
      (
        select distinct on (t.node_from, t.node_to)
          ST_SetSRID(
            ST_MakeLine(
              ST_MakePoint(
                ST_X(ST_StartPoint(seg_geom)),
                ST_Y(ST_StartPoint(seg_geom)),
                case when node_from = node
                then
                  agg_cost
                else
                  agg_cost - walk_time
                end
              ),
              ST_MakePoint(
                ST_X(ST_EndPoint(seg_geom)),
                ST_Y(ST_EndPoint(seg_geom)),
                case when node_from = node
                then
                  agg_cost - walk_time
                else
                  agg_cost
                end
              )
            ),
            4326
          ) as geom
        from
          (
            select * from drivingDistance
            union all (
              select distinct on (full_tree.seg_id) full_tree.seg_id as edge, m2.node, m2.agg_cost, full_tree.seg_id, full_tree.node_from, full_tree.node_to, full_tree.seg_geom, full_tree.length, m2.agg_cost - m3.agg_cost as walk_time
              from osm_road_segments full_tree
                LEFT JOIN drivingDistance m1
                  on full_tree.seg_id = m1.seg_id
                join drivingDistance m2
                  on full_tree.node_from = m2.node
                join drivingDistance m3
                  on full_tree.node_to = m3.node
              where m1.seg_id is null
                and full_tree.walk_time is not null
                and ST_Intersects(full_tree.seg_geom::geometry, possible_area)
                order by full_tree.seg_id, m2.agg_cost
            )
          ) as t
        order by
          t.node_from,
          t.node_to,
          t.agg_cost
    ) as g
    where g.geom is not null;
	END;
$body$
LANGUAGE plpgsql;
