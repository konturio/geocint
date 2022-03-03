-- Get all hexs on 8 resolution, that cover prescale_to_osm_boundaries 
-- Calculate population part per hex as divide source poly populatition 
-- by the number of hexs, that cover it
drop table if exists prescale_to_osm_h3_r8;
create table prescale_to_osm_h3_r8 as (
    select distinct on (h3)
            8                      as resolution,
            osm_id                 as osm_id,
            h3_polyfill(geom)      as h3,            
            population/count(h3_p) as divided_population        
    from (
        select distinct on (h3)
            osm_id            as id,
            population        as population,
            geom              as geom,
            h3_polyfill(geom) as h3_p
        from prescale_to_osm_boundaries
          ) squ
    group by osm_id, population, geom
);

drop table if exists prescale_to_osm_boundaries;