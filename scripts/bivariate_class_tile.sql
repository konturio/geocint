COPY (
  SELECT encode(ST_AsMVT(q, 'bivariate_class', 4096, 'geom'), 'hex')
  FROM (
    SELECT bivariate_class, ST_AsMvtGeom(geom, TileBBox(:z, :x, :y), 512, 0, false) AS geom
    FROM osm_quality_bivariate_tiles
    WHERE geom && TileBBox(:z, :x, :y)
    AND ST_Intersects(geom, TileBBox(:z, :x, :y))
  ) AS q
) TO STDOUT;
