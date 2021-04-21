drop table if exists :buildings_h3;
create table :buildings_h3 as (
    select h3_geo_to_h3(ST_PointOnSurface(wkb_geometry), 8) as h3,
           count(*) as building_count
    from :buildings
    group by 1
);
