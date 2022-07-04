-- Subdivided country boundaries
-- To refactor it later after hexagonify boundaries ready
drop table if exists country_boundaries_subdivided_in;
create table country_boundaries_subdivided_in as
select coalesce(tags ->> 'name:en', tags ->> 'int_name', name) as name_en,
       ST_Subdivide(geom)                                as geom
from osm_admin_boundaries where admin_level = '2';
create index on country_boundaries_subdivided_in using gist(geom);

-- Count buildings without using osm buildings where
drop table if exists building_count_for_missing_roads_grid_h3;
create table building_count_for_missing_roads_grid_h3 as (
    select h3,
           max(building_count) as building_count
    from (
             select h3, building_count
             from morocco_buildings_h3
             union all
             select h3, building_count
             from microsoft_buildings_h3
             union all
             select h3, building_count
             from geoalert_urban_mapping_h3
             union all
             select h3, building_count
             from new_zealand_buildings_h3
             union all
             select h3, building_count
             from abu_dhabi_buildings_h3
         ) z
    where building_count > 5
    group by 1
);

-- Missing roads table based on difference between OpenStreetMap and Facebook datasets
drop table if exists osm_missing_roads;
create table osm_missing_roads as
with q as (select distinct on (s.h3, b.name_en) s.h3 as h3, -- on h3 can intersects w/ >1 cnt polygons
        b.name_en, s.geom,
        population,
        round(s.highway_length::numeric / 1000, 2) as osm_l,
        round((s.total_road_length - s.highway_length)::numeric / 1000, 2) as fb_l,
        abs(log(s.highway_length + 1) - log(s.total_road_length + 1)) as diff
    from stat_h3 s
    left join country_boundaries_subdivided_in b
        on ST_Intersects(s.h3::geometry, b.geom)
    where s.total_road_length > 0   -- fb roads
        and population > 100 -- take only places with population more than 100
        and s.resolution = 8
        and s.h3 in (select h3 from building_count_for_missing_roads_grid_h3)),-- take only places with building_count more than 5
res as (select h3, q.name_en, geom,
        -- doing this to take only N biggest diffs, N=100
        -- and biggest rounded to .1 diff within country and h3 w/ highest population 
        rank() over(partition by q.name_en order by round(diff::numeric, 1) desc, population desc) as rank_by_cnt,
        osm_l, fb_l, diff
    from q, (select name_en,
                percentile_cont(0.75) within group (order by population) as pcont,
                percentile_cont(0.5) within group (order by diff) as pdiff
            from q
            group by name_en) as pop_percentile
    where diff > 0
        and q.name_en = pop_percentile.name_en
        and population > pcont
        and diff > pdiff
        and diff > 0.25 -- some small countries has very small diff
        )
select
    h3,
    name_en as "Country",
    osm_l as "OSM roads length, km",
    fb_l as "Facebook roads length, km",
    diff,
    -- Generate link for JOSM remote desktop:
    'hrefIcon_[Edit in JOSM](http://localhost:8111/load_and_zoom?new_layer=True' ||
    '&left='    || ST_XMin(ST_Envelope(ST_Transform(geom, 4326))) ||
    '&right='  || ST_XMax(ST_Envelope(ST_Transform(geom, 4326))) ||
    '&top='    || ST_YMax(ST_Envelope(ST_Transform(geom, 4326))) ||
    '&bottom=' || ST_YMin(ST_Envelope(ST_Transform(geom, 4326))) || ')'    as "Place bounding box",
    now() as debug_created_at -- for debug purposes, will be dropped after problem solved
from res
where rank_by_cnt < 101; --limit to 100 for each country

-- Drop temporary tables
drop table if exists building_count_for_missing_roads_grid_h3;
drop table if exists country_boundaries_subdivided_in;