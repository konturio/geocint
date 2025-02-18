drop table if exists osm_hotels_h3;
create table osm_hotels_h3 as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3, -- here we use input geometry in EPSG:4326
           count(*)::float as osm_hotels_count,
           max(assesment)  as max_osm_hotels_assesment,
           avg(assesment)  as avg_osm_hotels_assesment,
           8::integer      as resolution
    from osm_hotels
    group by 1
);

call generate_overviews('osm_hotels_h3', '{osm_hotels_count,max_osm_hotels_assesment,avg_osm_hotels_assesment}'::text[], '{sum,max,avg}'::text[], 8);
