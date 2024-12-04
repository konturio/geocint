drop table if exists osm_education_venues_h3;
create table osm_education_venues_h3 as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(geom)::point, 8) as h3,
           nullif(count(*) filter (where type = 'kindergarten'), 0) as osm_kindergartens_count,
           nullif(count(*) filter (where type = 'school'), 0)       as osm_schools_count,
           nullif(count(*) filter (where type = 'college'), 0)      as osm_colleges_count,
           nullif(count(*) filter (where type = 'university'), 0)   as osm_universities_count,
           8::integer                                               as resolution
    from osm_education_venues
    group by 1
);

call generate_overviews('osm_education_venues_h3', '{osm_kindergartens_count,osm_schools_count,osm_colleges_count,osm_universities_count}'::text[], '{sum,sum,sum,sum}'::text[], 8);