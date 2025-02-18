drop table if exists osm_heritage_sites_h3;
create table osm_heritage_sites_h3 as (
    select 
       h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3, -- here we use input geometry in EPSG:4326
       count(*)::float                                       as osm_heritage_sites_count,
       min(heritage_admin_level)::float                      as min_osm_heritage_admin_level,
       8::integer                                            as resolution
    from osm_heritage_sites
    group by 1
);

call generate_overviews('osm_heritage_sites_h3', '{osm_heritage_sites_count,min_osm_heritage_admin_level}'::text[], '{sum,min}'::text[], 8);
