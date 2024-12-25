drop table if exists osm_transport_facilities_h3;
create table osm_transport_facilities_h3 as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8)              as h3,
           nullif(count(*) filter (where type = 'airport'), 0)                as osm_airports_count,
           nullif(count(*) filter (where type = 'railway_station'), 0)        as osm_railway_stations_count,
           nullif(count(*) filter (where type = 'public_transport_stops'), 0) as osm_public_transport_stops_count,
           8::integer                                                         as resolution,
           ST_Transform(h3_cell_to_boundary_geometry(h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8)), 3857) as geom
    from osm_transport_facilities
    group by 1,6
);

call generate_overviews('osm_transport_facilities_h3', '{osm_airports_count,osm_railway_stations_count,osm_public_transport_stops_count}'::text[], '{sum,sum,sum}'::text[], 8);
