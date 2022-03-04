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
        )
where admin_level = :current_level;

delete
from prescale_to_osm_boundaries
where geom is null
   or ST_IsEmpty(geom);
   
vacuum prescale_to_osm_boundaries;


-- Check overlap polys on the last(12) admin level
-- Resolve all conflicts with reducing poly with less population
do
$$
    begin 
        if :current_level = 11 then
            -- Create CTE with unique pairs of overlap polygons
            with prep as (
                select distinct on (ST_Area(ST_Intersection(o.geom, p.geom))) 
                    (case 
                        when o.population >= p.population 
                            then p.osm_id
                            else o.osm_id
                        end) as prep_id,
                    (case
                        when o.population >= p.population 
                            then p.geom
                            else o.geom
                        end) as f_geom,
                    (case
                        when o.population >= p.population 
                            then o.geom
                            else p.geom
                        end) as s_geom                                    
                from prescale_to_osm_boundaries o, prescale_to_osm_boundaries p 
                where ST_Overlaps(o.geom, p.geom) and o.id_0 <> p.id_0)

                -- Resolve overlap conflicts with reducing less population polygons
                update prescale_to_osm_boundaries 
                    set geom = ST_Difference(f_geom, s_geom)
                    from prep 
                    where osm_id = prep_id;
        end if;
    end;
$$;