drop table if exists morocco_buildings_h3;
create table morocco_buildings_h3 as (
    select h3_geo_to_h3(ST_PointOnSurface(geom)::point, 8) as h3,
           8                                               as resolution,
           count(*)                                        as building_count
    from morocco_buildings
    group by 1
);
