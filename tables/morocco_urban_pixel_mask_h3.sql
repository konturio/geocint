drop table if exists morocco_urban_pixel_mask_h3;
create table morocco_urban_pixel_mask_h3 as (
    select h3_geo_to_h3(ST_Transform(ST_Centroid(geom), 4326), 8) as h3,
           count(*)
           from morocco_urban_pixel_mask
    group by 1
);
