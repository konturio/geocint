-- Decimate borders to make non overlaping borders with right population
update prescale_to_osm_boundaries r
set admin_level      = admin_level + 1,
    geom             = coalesce(
            ST_Difference(
                    geom,
                    (
                        select ST_Union(geom)
                        from prescale_to_osm_boundaries d
                        where ST_Intersects(r.geom, ST_PointOnSurface(d.geom))
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
        )
where admin_level = :current_level;

-- Remove degenerated borders
delete
from prescale_to_osm_boundaries
where geom is null
   or ST_IsEmpty(geom);

-- Mark borders, which will be degenerated in the next iteration
update prescale_to_osm_boundaries p
        set isdeg = true
        where
        coalesce(ST_Difference(p.geom, (select ST_Union(d.geom)
                                    from prescale_to_osm_boundaries d
                                    where ST_Intersects(p.geom, ST_PointOnSurface(d.geom))
                                    and d.admin_level = p.admin_level + 1)), geom) is null 
        or ST_IsEmpty(coalesce(ST_Difference(p.geom, (select ST_Union(d.geom)
                                    from prescale_to_osm_boundaries d
                                    where ST_Intersects(p.geom, ST_PointOnSurface(d.geom))
                                    and d.admin_level = p.admin_level + 1)), geom));

-- Calculate scale coefficient, to keep population of degenerated borders
-- We need for this to make sure, that we have right population and population distribution
-- Bcs for general case sum(population on under level) not equal to general population
with cte as (
    select sum(o.population) as population,
           p.osm_id          as osm_id
    from prescale_to_osm_boundaries o,
         prescale_to_osm_boundaries p
    where ST_Intersects(p.geom, ST_PointOnSurface(o.geom))
          and o.admin_level = p.admin_level + 1
    group by p.osm_id
)
update prescale_to_osm_boundaries p
set pop_ulevel = p.population / c.population
from cte c
where p.osm_id = c.osm_id;

-- Scale population to prevent losing population
update prescale_to_osm_boundaries p
    set population = p.population * o.pop_ulevel 

    from prescale_to_osm_boundaries o
    where ST_Intersects(o.geom, ST_PointOnSurface(p.geom))
          and p.admin_level = o.admin_level + 1
          and o.isdeg = true;