drop table if exists ghs_building_height_grid_h3;
create table ghs_building_height_grid_h3 as (
    select h3,
           8              as resolution,
           max(value)     as max_height,
           avg(avg_value) as avg_height
    from (select (h3_raster_agg_to_h3(rast, 8, 'max')).*,
                 (h3_raster_agg_to_h3(rast, 8, 'avg')).value as avg_value from ghs_building_height_raster) m
    group by 1
);
