COPY (
    SELECT encode(ST_AsMVT(q, 'bivariate_class', 4096, 'geom'), 'hex')
    FROM (
             SELECT bivariate_class,
                    ST_AsMVTGeom(ST_Union(geom), ST_TileEnvelope(:z, :x, :y), 4096, 0, false) AS geom
             FROM osm_quality_bivariate_grid_1000
             WHERE zoom = :z
               AND geom && ST_TileEnvelope(:z, :x, :y)
             GROUP BY bivariate_class
         ) AS q
    ) TO STDOUT;
