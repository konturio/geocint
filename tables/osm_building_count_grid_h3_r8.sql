drop table if exists osm_building_count_grid_h3_r8;
create table osm_building_count_grid_h3_r8 as (
    select
        h3_geo_to_h3(ST_PointOnSurface(geog::geometry)::point, 8) as h3,
        8 as resolution,
        count(*) as building_count
    from
        osm_buildings
    where
        tags ? 'building'
    group by 1
    order by 1
);