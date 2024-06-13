drop table if exists osm_culture_venues_h3;
create table osm_culture_venues_h3 as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8)                         as h3,
           nullif(count(*) filter (where type = 'osm_historical_sites_and_museums'), 0)  as osm_historical_sites_and_museums_count,
           nullif(count(*) filter (where type = 'osm_art_venues'), 0)                    as osm_art_venues_count,
           nullif(count(*) filter (where type = 'osm_entertainment_venues'), 0)          as osm_entertainment_venues_count,
           nullif(count(*) filter (where type = 'osm_cultural_and_comunity_centers'), 0) as osm_cultural_and_comunity_centers_count
    from osm_culture_venues
    group by 1
);


call generate_overviews('osm_culture_venues_h3', '{osm_historical_sites_and_museums_count,osm_art_venues_count,osm_entertainment_venues_count,osm_cultural_and_comunity_centers_count}'::text[], '{sum,sum,sum,sum}'::text[], 8);
