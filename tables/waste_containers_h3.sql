drop table if exists waste_containers_h3_r8;
create table waste_containers_h3_r8 as (
    select osm_id                                       as osm_id,
           ST_Centroid(geog::geometry)                  as geom,
           h3_geo_to_h3(ST_Centroid(geog::geometry), 8) as h3
    from osm o
    where tags @> '{"amenity":"waste_basket"}'
       or tags @> '{"amenity":"waste_disposal"}'
       or tags @> '{"amenity":"recycling"}'
);

drop table if exists waste_containers_h3;
create table waste_containers_h3 as (
    select h3                                            as h3,
           count(distinct h3_geo_to_h3(geom, 10))        as waste_basket_coverage,
           8                                             as resolution
    from waste_containers_h3_r8
    group by 1
);

drop table if exists waste_containers_h3_r8;