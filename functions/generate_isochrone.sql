create or replace function generate_isochrone(
    geom geometry, -- start geometry
    avg_speed double precision, -- average speed (kilometers per hour)
    "time" double precision, -- time in minutes
    profile text -- OSRM profile,
)
    returns table(minutes integer, isochrone geometry)
    stable
    cost 10000
    language sql
as
$$
with etas as (
    select t.node, t.eta
    from ykyslomed.calculate_etas(geom, avg_speed, "time", profile) t
),
     delaunay as (
         select (ST_Dump(
                 ST_DelaunayTriangles(
                         ST_Collect(
                                 ST_SetSRID(
                                         ST_MakeLine(
                                                 ST_MakePoint(
                                                         ST_X(start), ST_Y(start), e1.eta
                                                     ),
                                                 ST_MakePoint(
                                                         ST_X(finish), ST_Y(finish), e2.eta
                                                     )
                                             ), 4326)
                             )
                     )
             )).geom
         from etas e1,
              etas e2,
              ykyslomed.osm_road_segments s,
              ST_StartPoint(s.seg_geom) "start",
              ST_EndPoint(s.seg_geom) "finish"
         where e1.node = s.node_from
           and e2.node = s.node_to)
select minutes,
       ST_ChaikinSmoothing(
               ST_CollectionExtract(
                       ST_Union(
                               ST_ConvexHull(
                                       ST_LocateBetweenElevations(
                                               ST_Boundary(geom),
                                               (minutes - 1) * 60,
                                               minutes * 60
                                           )
                                   )
                           ), 3
                   ))
from delaunay,
     generate_series(1, ceil("time")::integer) minutes
group by minutes;
$$;
