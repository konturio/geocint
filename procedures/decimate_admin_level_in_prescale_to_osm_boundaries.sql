update prescale_to_osm_boundaries r
set admin_level      = admin_level + 1,
    geom             = coalesce(
            ST_Difference(
                    geom,
                    (
                        select ST_Union(geom)
                        from prescale_to_osm_boundaries d
                        where
                          -- TODO: partial overlaps
                            ST_Intersects(r.geom, ST_PointOnSurface(d.geom))
                          and d.admin_level = r.admin_level + 1
                    )
                ),
            geom
        ),
    population       = coalesce(
                population - (
                select sum(d.population)
                from prescale_to_osm_boundaries d
                where ST_Intersects(r.geom, ST_PointOnSurface(d.geom))
                  and d.admin_level = r.admin_level + 1
            ),
                population
        ),
    area             = null
where admin_level = :current_level;

delete
from prescale_to_osm_boundaries
where geom is null
   or ST_IsEmpty(geom);

update prescale_to_osm_boundaries
set area = ST_Area(ST_Transform(geom, 4326)::geography)
where area is null;

vacuum prescale_to_osm_boundaries;

-- TODO: process overlaps on same admin level
-- TODO: remove water
