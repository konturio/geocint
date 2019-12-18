copy (
    with user_hex as (
        select osm_user                                                                     as top_user,
               ST_AsMVTGeom(st_centroid(geom), ST_TileEnvelope(:z, :x, :y), 8192, 64, true) as centroid,
               ST_AsMVTGeom(geom, ST_TileEnvelope(:z, :x, :y), 8192, 64, true)              as geom,
               h3
        from osm_users_hex
        where resolution = LEAST(calculate_h3_res(:z), 8)
          and geom && ST_TileEnvelope(:z, :x, :y)
    )
    select encode(ST_AsMVT(q, 'users', 8192, 'centroid') || ST_AsMVT(q2, 'hexagon', 8192, 'geom'), 'hex')
    from (
             select top_user, centroid, h3
             from user_hex
         ) as q,
         (
             select top_user, geom, h3
             from user_hex
         ) as q2
    where q.top_user = q2.top_user and q.h3 = q2.h3
    ) to stdout;
