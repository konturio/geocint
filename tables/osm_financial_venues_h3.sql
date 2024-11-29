drop table if exists osm_financial_venues_h3;
create table osm_financial_venues_h3 as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3,
           nullif(count(*) filter (where type = 'bank'), 0)      as osm_banks_count,
           nullif(count(*) filter (where type = 'atm'), 0)       as osm_atms_count
           8::integer                                            as resolution
    from osm_financial_venues
    group by 1
);

call generate_overviews('osm_financial_venues_h3', '{osm_banks_count,osm_atms_count}'::text[], '{sum,sum}'::text[], 8);
