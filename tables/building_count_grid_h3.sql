drop table if exists building_count_grid_h3;
create table building_count_grid_h3 as (
    select h3,
           8 as resolution,
           max(building_count) as building_count
    from (
             select h3, 1::int as building_count
             from morocco_urban_pixel_mask_h3
             union all
             select h3, building_count
             from morocco_buildings_h3
             union all
             select h3, building_count
             from us_microsoft_buildings_h3
             union all
             select h3, building_count
             from osm_building_count_grid_h3_r8
             union all
             select h3, 1::int as building_count
             from copernicus_builtup_h3
             union all
             select h3, building_count
             from africa_microsoft_buildings_h3
             union all
             select h3, building_count
             from canada_microsoft_buildings_h3
             union all
             select h3, building_count
             from australia_microsoft_buildings_h3
         ) z
    group by 1
);

alter table building_count_grid_h3
    set (parallel_workers = 32);

do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into building_count_grid_h3 (h3, building_count, resolution)
                select h3_to_parent(h3) as h3, sum(building_count) as building_count, (res - 1) as resolution
                from building_count_grid_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;