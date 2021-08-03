copy (
    select encode(ST_AsMVT(q, 'stats', 8192, 'geom'), 'hex')
    from
        (
            select
                count,
                count_6_months,
                building_count,
                building_count_6_months,
                highway_length,
                highway_length_6_months,
                osm_users,
                population,
                gdp,
                coalesce(min_ts, 0) as min_ts,
                coalesce(max_ts, 0) as max_ts,
                coalesce(avgmax_ts, 0) as avgmax_ts,
                area_km2,
                local_hours,
                total_hours,
                view_count,
                one,
                total_building_count,
                wildfires,
                covid19_vaccines,
                avg_slope,
                forest,
                avg_ndvi,
                covid19_confirmed,
                population_v2,
                industrial_area,
                volcanos_count,
                pop_under_5_total,
                pop_over_65_total,
                poverty_families_total,
                pop_disability_total,
                pop_not_well_eng_speak,
                pop_without_car,
                evergreen_needle_leaved_forest,
                shrubs,
                herbage,
                unknown_forest,
                ST_AsMVTGeom(geom, ST_TileEnvelope(:z, :x, :y), 8192, 64, true) as geom
            from
                stat_h3
            where
                  zoom = :z
              and geom && ST_TileEnvelope(:z, :x, :y)
        ) as q
    ) to stdout;
