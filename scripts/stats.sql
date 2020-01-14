copy (
    select encode(ST_AsMVT(q, 'stats', 8192, 'geom'), 'hex')
    from (
             select count,
                    building_count,
                    highway_length,
                    amenity_count,
                    osm_users,
                    osm_local_users,
                    population,
                    avg_ts,
                    max_ts,
                    p90_ts,
                    area_km2,
                    ST_AsMVTGeom(geom, ST_TileEnvelope(:z, :x, :y), 8192, 64, true) as geom
             from osm_object_count_grid_h3_with_population
             where zoom = :z
               and geom && ST_TileEnvelope(:z, :x, :y)
         ) as q
    ) to stdout;
