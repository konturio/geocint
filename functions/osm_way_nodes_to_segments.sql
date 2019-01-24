create or replace function osm_way_nodes_to_segments(geom geometry,
                                                     way_nodes bigint[])
  returns table
          (
            node_from bigint,
            node_to   bigint,
            seg_geom  geometry
          )
  language sql
as
$$
select
  n                                 as node_from,
  lead(n) over ()                   as node_to,
  ST_MakeLine(pt, lead(pt) over ()) as seg_geom
from
  (
    select
      (ST_DumpPoints(geom)).geom as pt,
      unnest(way_nodes)          as n
  ) z
$$
  immutable
  strict
  parallel safe
  cost 10000;