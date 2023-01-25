-- this script generates MVT tiles with OSM active contributors h3 hexes for a given XYZ
with 
      -- zoom table is a set of pairs "optimal h3 resolution", "tile zoom level" generated with logic described below
      -- for tile zoom levels < 8 should be generated one pair: current zoom level and optimal h3 resolution for it
      -- for tile zoom levels >= 8 should be generated several pairs, including optimal h3 resolutions for tiles zoom levels from 8 to 12
      zoom as (select tile_zoom_level_to_h3_resolution(zoom_lvl, max_h3_resolution := 8) as tile_resolution, zoom_lvl
              from (select generate_series(z1, z2) as zoom_lvl
                    from (select case when $1 < 8 then $1 else 8 end  as z1,
                                 case when $1 < 8 then $1 else 12 end as z2) a) b),
      -- user_hex table is a set of MVT geometries (hex polygons and centroids for labeling) with metadata related to top OSM contributors
      -- inside given XYZ at h3 resolutions levels calculated above
      user_hex as (select osm_user                                                                                   as top_user,
                         ST_AsMVTGeom(ST_Transform(h3::geometry, 3857), 
                                      ST_TileEnvelope($1, $2, $3), 8192, 64, true)                                   as centroid,
                         ST_AsMVTGeom(geom, ST_TileEnvelope($1, $2, $3), 8192, 64, true)                             as geom,
                         h3,
                         resolution,
                         is_local,
                         zoom.zoom_lvl
                  from osm_users_hex,
                       zoom
                  where resolution = zoom.tile_resolution
                    and geom && ST_TileEnvelope($1, $2, $3))
select ST_AsMVT(q, 'users', 8192, 'centroid') || ST_AsMVT(q2, 'hexagon', 8192, 'geom')
from (select top_user, centroid, h3, zoom_lvl as zoom, is_local
      from user_hex) as q,
     (select top_user, geom, h3, zoom_lvl as zoom, is_local
      from user_hex) as q2
where q.top_user = q2.top_user
  and q.h3 = q2.h3
  and q.zoom = q2.zoom;
