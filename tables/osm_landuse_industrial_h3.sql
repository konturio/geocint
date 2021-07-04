drop table if exists osm_landuse_industrial_h3;
create table osm_landuse_industrial_h3 as (
    select p.h3,
           sum(ST_Area(ST_Intersection(p.geom, r.geom)) / ST_Area(p.geom)) as industrial_area
    from osm_landuse_industrial p
      join ghs_globe_residential_vector r on ST_Intersects(p.geom, r.geom)
    group by p.h3
);
update residential_pop_h3 set residential = 1 where residential > 1;