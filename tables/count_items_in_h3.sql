drop table if exists :table_h3;
create table :table_h3 as (
    select h3_geo_to_h3(ST_PointOnSurface(geom), 8) as h3, -- here we use input geometry in EPSG:4326
           count(*)::float as :item_count
    from :table
    group by 1
);
