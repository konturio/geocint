update osm_population_raw r
set
  admin_level      = admin_level + 1,
  geom             = coalesce(
      ST_Difference(
          geom,
          (
            select
              ST_Union(geom)
            from
              osm_population_raw d
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
        select
          sum(d.population)
        from
          osm_population_raw d
        where
          ST_Intersects(r.geom, ST_PointOnSurface(d.geom))
          and d.admin_level = r.admin_level + 1
      ),
        population
    ),
  people_per_sq_km = null,
  area             = null
where
  admin_level = :current_level;

delete
from osm_population_raw
where geom is null or ST_IsEmpty(geom);

update osm_population_raw
set area = ST_Area(ST_Transform(geom, 4326)::geography)
where area is null;

update osm_population_raw
set people_per_sq_km = 1000000 * population / area
where people_per_sq_km is null;

vacuum osm_population_raw;

-- TODO: process overlaps on same admin level
-- TODO: remove water
