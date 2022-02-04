-- Subdivided country boundaries
-- To refactor it later after hexagonify boundaries ready
drop table if exists country_boundaries_subdivided_in;
create table country_boundaries_subdivided_in as
select coalesce(tags ->> 'name:en', tags ->> 'int_name', name) as name_en,
       ST_Subdivide(geom)                                as geom
from osm_admin_boundaries where admin_level = '2';
create index on country_boundaries_subdivided_in using gist(geom);


-- Missing roads table based on difference between OpenStreetMap and Facebook datasets
drop table if exists osm_missing_roads;
create table osm_missing_roads as
select s.h3                                                               as h3,
       b.name_en                                                          as "Country",
       round(s.highway_length::numeric / 1000, 2)                         as "OSM roads length, km",
       round((s.total_road_length - s.highway_length)::numeric / 1000, 2) as "Facebook roads length, km",
       abs(log(s.highway_length + 1) - log(s.total_road_length + 1))      as  diff,
       'left='    || ST_XMin(ST_Envelope(ST_Transform(s.geom, 4326))) ||
       '&right='  || ST_XMax(ST_Envelope(ST_Transform(s.geom, 4326))) ||
       '&top='    || ST_YMax(ST_Envelope(ST_Transform(s.geom, 4326))) ||
       '&bottom=' || ST_YMin(ST_Envelope(ST_Transform(s.geom, 4326)))     as "Place bounding box"
from stat_h3 s
left join country_boundaries_subdivided_in b
       on ST_Intersects(s.h3::geometry, b.geom)
where s.total_road_length > 0
  and s.resolution = 8;

-- Drop temporary tables
drop table if exists country_boundaries_subdivided_in;


-- Update timestamp in reports table (for further export to reports API JSON):
update osm_reports_list
set last_updated = (select meta->'data'->'timestamp'->>'last' as updated from osm_meta)
where id = 'osm_missing_roads';