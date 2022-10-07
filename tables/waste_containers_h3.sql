drop table if exists waste_containers_h3_r8;

-- according to research 75m is an optimal distance betweem thash bins
-- 75 meters provide 99% coverage
create table waste_containers_h3_r8 as (
    select osm_id,
           h3_geo_to_h3(ST_Centroid(geog::geometry), 8) as h3
    from osm o
    where tags @> '{"amenity":"waste_basket"}'
       or tags @> '{"amenity":"waste_disposal"}'
       or tags @> '{"amenity":"recycling"}'
);

drop table if exists waste_containers_h3;
create table waste_containers_h3 as (
    select h3                 as h3,
           count(osm_id)      as number_of_waste_containers,
           8                  as resolution
    from waste_containers_h3_r8
    group by 1
);

drop table if exists waste_containers_h3_r8;
