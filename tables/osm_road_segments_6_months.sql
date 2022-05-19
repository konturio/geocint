drop table if exists osm_road_segments_6_months;

create table osm_road_segments_6_months as
    select z.ordinality as id_of_segm,
        osm_id,
        8::int as resolution,
        h3_geo_to_h3(ST_PointOnSurface(z.geom)::point, 8) as h3,
        ST_Length(z.geom::geography) as length,
        z.geom
    from
        osm_roads as o,
        lateral ST_DumpSegments(geom) with ordinality as z
    where
        -- this params same as for osm_road_segments
        -- ts same as for osm_object_count_grid_h3
         (walk_speed is not null
      or drive_speed is not null)
      and ts > (select (meta -> 'data' -> 'timestamp' ->> 'last')::timestamptz
            from osm_meta) - interval '6 months';