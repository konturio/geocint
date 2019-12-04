copy (
    select encode(ST_AsMVT(q, 'users', 8192, 'geom'), 'hex')
    from (
             select top_user,
                    ST_AsMVTGeom(geom, ST_TileEnvelope(:z, :x, :y), 8192, 64, true) as geom
             from osm_object_count_grid_h3_with_population
             where zoom = :z
               and geom && ST_TileEnvelope(:z, :x, :y)
         ) as q
    ) to stdout;
