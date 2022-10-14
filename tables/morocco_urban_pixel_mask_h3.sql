drop table if exists morocco_urban_pixel_mask_h3;
create table morocco_urban_pixel_mask_h3 as (
    select h3_lat_lng_to_cell(ST_Transform(ST_Centroid(geom), 4326)::point, 8) as h3,
           count(*)
           from morocco_urban_pixel_mask
    group by 1
);
