  with user_hex as (
      select osm_user                                                                     as top_user,
              ST_AsMVTGeom(ST_Transform(h3::geometry, 3857), ST_TileEnvelope(:z, :x, :y), 8192, 64, true) as centroid,
              ST_AsMVTGeom(geom, ST_TileEnvelope(:z, :x, :y), 8192, 64, true)              as geom,
              h3,
              resolution,
              is_local,
              zoom.zoom_lvl
      from osm_users_hex,
            calculate_h3_res(:z) zoom
      where resolution = zoom.tile_resolution
        and geom && ST_TileEnvelope(:z, :x, :y)
  )
  select ST_AsMVT(q, 'users', 8192, 'centroid') || ST_AsMVT(q2, 'hexagon', 8192, 'geom')
  from (
            select top_user, centroid, h3, zoom_lvl as zoom, is_local
            from user_hex
        ) as q,
        (
            select top_user, geom, h3, zoom_lvl as zoom, is_local
            from user_hex
        ) as q2
  where q.top_user = q2.top_user
    and q.h3 = q2.h3
    and q.zoom = q2.zoom;
