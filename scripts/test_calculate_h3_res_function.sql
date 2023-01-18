-- compare h3 resolutions based on input tile zoom level returned from old and new function versions
-- if 1 returned then h3_resolutions are same. if 0 - then different.
-- 12 zoom_level is max in test due to old function doesn't produce h3 resolution outputs for greater values (hardcoded)
with zoom_levels as (select generate_series(0, 12) zoom),
     previous_outputs_raw as (select (calculate_h3_res(zoom_levels.zoom)).zoom_lvl        as zoom_lvl,
                                     (calculate_h3_res(zoom_levels.zoom)).tile_resolution as h3_res
                              from zoom_levels),
     previous_outputs as (select distinct zoom, h3_res
                          from zoom_levels
                                   left join previous_outputs_raw on zoom_levels.zoom = previous_outputs_raw.zoom_lvl
                          order by zoom),
     new_outputs as (select zoom, calculate_h3_res_new(zoom, hex_edge_pixels := 22) as h3_res from zoom_levels),
     comparison as (select old.zoom   as zoom,
                           old.h3_res as old_h3_res,
                           new.h3_res as new_h3_res
                    from previous_outputs old
                             join new_outputs new on old.zoom = new.zoom)
select min(case when old_h3_res = new_h3_res then 1 else 0 end) as equal
from comparison;