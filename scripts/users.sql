copy (
    select encode(ST_AsMVT(q, 'users', 8192, 'centroid') || ST_AsMVT(q, 'hexagon', 8192, 'geom'), 'hex')
    from (
             select osm_user as top_user,
                    ST_AsMVTGeom(st_centroid(geom), ST_TileEnvelope(:z, :x, :y), 8192, 64, true) as centroid,
                    ST_AsMVTGeom(geom, ST_TileEnvelope(:z, :x, :y), 8192, 64, true) as geom
             from osm_users_hex
             where resolution = LEAST(calculate_h3_res(:z), 8)
               and geom && ST_TileEnvelope(:z, :x, :y)
         ) as q
    ) to stdout;
