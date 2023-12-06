drop table if exists building_count_grid_h3;
create table building_count_grid_h3 as (
    select h3,
           10                  as resolution,
           max(building_count) as building_count
    from (
             select h3, 1::int as building_count
             from morocco_urban_pixel_mask_h3
             union all
             select h3, building_count
             from morocco_buildings_h3
             union all
             select h3, building_count
             from microsoft_buildings_h3
             union all
             select h3, building_count
             from osm_building_count_grid_h3_r10
             union all
             select h3, 1::int as building_count
             from copernicus_builtup_h3
             union all
             select h3, building_count
             from geoalert_urban_mapping_h3
             union all
             select h3, building_count
             from new_zealand_buildings_h3
             union all
             select h3, building_count
             from abu_dhabi_buildings_h3
         ) z
    group by 1
);
