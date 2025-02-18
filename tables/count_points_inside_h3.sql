drop table if exists :table_h3;
create table :table_h3 as (
    select h3_lat_lng_to_cell(geom::point, 8) as h3, -- here we use input geometry in EPSG:4326
           count(*) as :item_count,
           8    as resolution
    from :table
    group by 1
);
