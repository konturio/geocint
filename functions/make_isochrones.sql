CREATE OR REPLACE FUNCTION make_isochrones(IN pointid integer[])
RETURNS TABLE(
	min INT,
	geom geometry
)
AS
$body$
DECLARE
	extra_radius integer := 3000;
	time_limit integer := 2*60*60;
	isochrone_interval integer := 5*60;
BEGIN
	RETURN QUERY
	with delaunay_triangles as (
		select
	    ST_ZMin(z.geom) as tmin,
	    ST_ZMax(z.geom) as tmax,
	    z.geom
	  from
	    (
	      select
	        (ST_Dump(ST_Triangulate2DZ(ST_Node(ST_Transform(ST_Collect(tst.geom), 3857))))).geom geom
	      from
	      	(select c.geom from
	      		(select distinct on (ST_FORCE2D(t.geom)) t.geom
	      			from temp_spanning_tree t where point_id = ANY(pointid)
	      			order by ST_FORCE2D(t.geom), st_zmax(t.geom)) as c
	  			order by st_zmax(c.geom)
	  		) as tst
	    ) as z
	  where
	    ST_Perimeter(z.geom) < extra_radius
    )
	select
    (isochrone_number * isochrone_interval) / 60 as min,
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
        ), 3
      )
    ) as geom
  from
    generate_series(1, ceil(time_limit / isochrone_interval)::integer) isochrone_number
      join lateral (select *
                    from
                      delaunay_triangles
                    where
                      tmin <= isochrone_number * isochrone_interval
                    and tmax >= (isochrone_number - 1) * isochrone_interval
      ) t on true
      group by 1;
END;
$body$
LANGUAGE plpgsql;
