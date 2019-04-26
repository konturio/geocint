COPY (
    SELECT encode(ST_AsMVT(q, 'bivariate_class', 512, 'geom'), 'hex')
    FROM (
             SELECT bivariate_class,
                    ST_AsMvtGeom(ST_Intersection(ST_Simplify(ST_Union(geom), 0), TileBBox(:z, :x, :y)),
                                 TileBBox(:z, :x, :y), 512, 0, false) AS geom
             FROM osm_quality_bivariate_grid_1000
             WHERE zoom = :z
               AND geom && TileBBox(:z, :x, :y)
             GROUP BY bivariate_class, geom
         ) AS q
    ) TO STDOUT;