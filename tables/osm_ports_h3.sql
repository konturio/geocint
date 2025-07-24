drop table if exists osm_ports_h3;
create table osm_ports_h3 as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3,
           count(*) as osm_ports_count,
           8 as resolution
    from osm_ports
    group by 1
);

call generate_overviews('osm_ports_h3', '{osm_ports_count}'::text[], '{sum}'::text[], 8);

create index on osm_ports_h3 (h3);
