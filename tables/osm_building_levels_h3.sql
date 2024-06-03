drop table if exists osm_building_levels_h3_in;
create table osm_building_levels_h3_in as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3, -- here we use input geometry in EPSG:4326
           coalesce(max(levels), ceil(max(height)/3), null) as max_levels,
           coalesce(avg(levels), ceil(avg(height)/3), null) as avg_levels
    from osm_buildings
    where levels < 165 or height < 840
    group by 1
);

drop table if exists osm_building_levels_h3;
create table osm_building_levels_h3 as (
    select h3 as h3,
           8  as resolution,
           max_levels,
           avg_levels
    from osm_building_levels_h3_in
    where max_levels is not null 
);

drop table if exists osm_building_levels_h3_in;