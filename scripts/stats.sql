copy (
    select encode(ST_AsMVT(q, 'stats', 8192, 'geom'), 'hex')
    from
        (
            select
                count,
                building_count,
                highway_length,
                osm_users,
                population,
                gdp,
                coalesce(avg_ts, 0) as avg_ts,
                coalesce(max_ts, 0) as max_ts,
                coalesce(p90_ts, 0) as p90_ts,
                area_km2,
                local_hours,
                total_hours,
                view_count,
                1 :: double precision as one,
                ST_AsMVTGeom(geom, ST_TileEnvelope(:z, :x, :y), 8192, 64, true) as geom
            from
                stat_h3
            where
                  zoom = :z
              and geom && ST_TileEnvelope(:z, :x, :y)
        ) as q
    ) to stdout;
