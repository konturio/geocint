drop table if exists morocco_buildings_manual;
create table morocco_buildings_manual as (
    select building_height, wkb_geometry, footprint from agadir
    union all
    select building_height::integer, wkb_geometry::geometry, footprint::geometry from casablanca
    union all
    select building_height, wkb_geometry, footprint from chefchaouen
    union all
    select building_height, wkb_geometry, footprint from fes
    union all
    select building_height, wkb_geometry, footprint from meknes
);