drop table if exists africa_microsoft_buildings_h3;
create table africa_microsoft_buildings_h3 as (
    select h3_geo_to_h3(ST_PointOnSurface(wkb_geometry), 8) as h3,
    count(*)
    from africa_microsoft_buildings
    group by 1
);

