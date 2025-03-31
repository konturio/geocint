drop table if exists waste_basket_coverage_h3_in;
create table waste_basket_coverage_h3_in as (
    select h3_lat_lng_to_cell(ST_Centroid(geog::geometry)::point, 11) as h3,
           11::integer                                                as resolution
    from osm o
    where tags @> '{"amenity":"waste_basket"}'
       or tags @> '{"amenity":"waste_disposal"}'
       or tags @> '{"amenity":"recycling"}'
    group by 1
);

-- according to research, one trash can covers an area of 70 meters around, 
-- so we consider the central and neighboring hexagons on level 11 as covered,
-- which gives a diameter of the covered area ~140 meters
drop table if exists waste_basket_coverage_h3_mid;
create table waste_basket_coverage_h3_mid as (
    select h3,
           ST_Area(h3_cell_to_boundary_geography(h3)) / 1000000.0 as waste_basket_coverage_area_km2,
           resolution
    from waste_basket_coverage_h3_in
    union all
    select h3,
           ST_Area(h3_cell_to_boundary_geography(h3)) / 1000000.0 as waste_basket_coverage_area_km2,
           11::integer                                            as resolution
    from (select h3_grid_ring_unsafe(h3, 1) as h3
          from waste_basket_coverage_h3_in
          group by 1)
    where h3 not in (select h3 from roads_h3_r82 where resolution = 11)
);

drop table if exists waste_basket_coverage_h3_in;

call generate_overviews('waste_basket_coverage_h3_mid', '{waste_basket_coverage_area_km2}'::text[], '{sum}'::text[], 11);

call dither_area_to_not_bigger_than_100pc_of_hex_area('waste_basket_coverage_h3_mid', 'waste_basket_coverage_h3', '{waste_basket_coverage_area_km2}'::text[], 11);

drop table if exists waste_basket_coverage_h3_mid;
