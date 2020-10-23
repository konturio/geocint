drop table if exists us_microsoft_buildings_h3;
create table us_microsoft_buildings_h3 as (
    select h3_geo_to_h3(ST_PointOnSurface(wkb_geometry), 8) as h3,
    count(*)
    from us_microsoft_buildings
    group by 1
);
