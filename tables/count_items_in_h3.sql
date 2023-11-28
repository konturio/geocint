drop table if exists :table_h3;
create table :table_h3 as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 10) as h3, -- here we use input geometry in EPSG:4326
           count(*)::float as :item_count
    from :table
    group by 1
);
