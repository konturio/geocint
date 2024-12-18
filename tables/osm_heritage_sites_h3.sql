drop table if exists osm_heritage_sites_h3;
create table osm_heritage_sites_h3 as (
    select l.h3                                 as h3,
           count(k.*)::float                    as osm_heritage_sites_count,
           min(k.heritage_admin_level)::float   as min_osm_heritage_admin_level
           8::integer                           as resolution
    from osm_heritage_sites k,
         land_polygons_h3_r8 l
    where ST_Intersects(k.geom, l.geom)
    group by 1
);

call generate_overviews('osm_heritage_sites_h3', '{osm_heritage_sites_count,min_osm_heritage_admin_level}'::text[], '{sum,min}'::text[], 8);