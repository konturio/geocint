copy (
    select encode(ST_AsMVT(q, 'bivariate_class', 4096, 'geom'), 'hex')
    from (
             select bivariate_class,
                    ST_AsMVTGeom((ST_Dump(ST_Union(geom))).geom, ST_TileEnvelope(:z, :x, :y), 4096, 256, true) as geom
             from osm_quality_bivariate_grid_h3
             where zoom = :z
               and geom && ST_TileEnvelope(:z, :x, :y)
             group by bivariate_class
         ) as q
    ) to stdout;
