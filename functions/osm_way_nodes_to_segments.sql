drop function if exists osm_way_nodes_to_segments;

create or replace function osm_way_nodes_to_segments(geom geometry,
                                                     way_nodes bigint[],
                                                     osm_id bigint)
  returns table
          (
            uosm_id   bigint,
            node_from bigint,
            node_to   bigint,
            seg_geom  geometry
          )
  language sql
as
$$
select
  osm_id * 10000 + ROW_NUMBER() over()     as seg_id,
  n                                        as node_from,
  lead(n) over ()                          as node_to,
  ST_MakeLine(pt, lead(pt) over ())        as seg_geom
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