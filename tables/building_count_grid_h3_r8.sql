drop table if exists building_count_grid_h3_r8;
create table building_count_grid_h3_r8 as (
    select h3,
           8 as resolution,
           max(building_count) as building_count
    from (
             select h3, count as building_count
             from morocco_urban_pixel_mask_h3
             union all
             select h3, building_count
             from morocco_buildings_h3
             union all
             select h3, count as building_count
             from us_microsoft_buildings_h3
             union all
             select h3, building_count
             from osm_building_count_grid_h3_r8
         ) z
    group by 1
);
