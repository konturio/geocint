COPY (
    SELECT encode(ST_AsMVT(q, 'bivariate_class', 4096, 'geom'), 'hex')
    FROM (
             SELECT bivariate_class,
                    ST_AsMvtGeom(ST_Union(geom), TileBBox(:z, :x, :y), 4096, 0, false) AS geom
             FROM osm_quality_bivariate_grid_1000
             WHERE zoom = :z
               AND geom && TileBBox(:z, :x, :y)
             GROUP BY bivariate_class
         ) AS q
    ) TO STDOUT;
