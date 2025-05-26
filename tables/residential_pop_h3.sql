drop table if exists residential_pop_h3;
create table residential_pop_h3 as (
    select p.h3,
           sum(ST_Area(ST_Intersection(p.geom, r.geom)) / ST_Area(p.geom)) AS residential
    from kontur_population_h3 p
         join ghs_globe_residential_vector r on p.geom && r.geom
    where ST_Intersects(p.geom, r.geom)
    group by p.h3
);

update residential_pop_h3 set residential = 1 where residential > 1;
