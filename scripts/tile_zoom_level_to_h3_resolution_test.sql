-- compare h3 resolutions based on input tile zoom level returned from old (calculate_h3_res) and new (tile_zoom_level_to_h3_resolution) function versions
-- if 1 returned then h3 resolutions are same. if 0 - then different.
with zoom_levels as (select generate_series(0, 12) zoom),
     previous_outputs as (select *
                          -- key values produced by previous function
                          from (VALUES (0, 0),
                                       (1, 0),
                                       (2, 0),
                                       (3, 1),
                                       (4, 2),
                                       (5, 3),
                                       (6, 3),
                                       (7, 4),
                                       (8, 5),
                                       (9, 5),
                                       (10, 6),
                                       (11, 7),
                                       (12, 8)) as q (zoom, h3_res)),
     new_outputs as (select zoom, tile_zoom_level_to_h3_resolution(zoom, hex_edge_pixels := 44) as h3_res
                     from zoom_levels),
     comparison as (select old.zoom   as zoom,
                           old.h3_res as old_h3_res,
                           new.h3_res as new_h3_res
                    from previous_outputs old
                             join new_outputs new on old.zoom = new.zoom)
select min(case when old_h3_res = new_h3_res then 1 else 0 end) as equal
from comparison;