drop table if exists waste_containers_h3_r8;
create table waste_containers_h3_r8 as (
    select osm_id                                       as osm_id,
           ST_Centroid(geog::geometry)                  as geom,
           h3_lat_lng_to_cell(ST_Centroid(geog::geometry)::point, 8) as h3
    from osm o
    where tags @> '{"amenity":"waste_basket"}'
       or tags @> '{"amenity":"waste_disposal"}'
       or tags @> '{"amenity":"recycling"}'
);

drop table if exists waste_containers_h3;
create table waste_containers_h3 as (
    select h3                                            as h3,
           count(distinct h3_lat_lng_to_cell(geom::point, 10))        as waste_basket_coverage,
           8                                             as resolution
    from waste_containers_h3_r8
    group by 1
);

drop table if exists waste_containers_h3_r8;