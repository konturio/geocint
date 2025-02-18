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
with q as (select distinct on (s.h3, b.name_en) s.h3 as h3, -- on h3 can intersects w/ >1 cnt polygons
        b.name_en, s.geom,
        population,
        round(coalesce(o.highway_length,0)::numeric, 2) as osm_l,
        round(fbr.fb_roads_length::numeric / 1000.0, 2) as fb_l,
        abs(log(coalesce(o.highway_length,0) + 1) - log(coalesce(o.highway_length, 0) + (fbr.fb_roads_length / 1000.0) + 1)) as diff
    from 
        facebook_roads_h3 fbr 
        left join building_count_grid_h3 b on fbr.h3 = b.h3
        left join osm_object_count_grid o on fbr.h3 = o.h3 
        left join country_boundaries_subdivided_in b
            on ST_Intersects(fbr.h3::geometry, b.geom)
    where o.total_road_length > 0   -- fb roads
        and population > 2 -- take only places with population more than 2
        and fbr.resolution = 8
        and b.total_building_count > 1),-- take only places with building_count more than 1
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
    'hrefIcon_[Edit in JOSM](http://127.0.0.1:8111/load_and_zoom?new_layer=True' ||
    '&left='    || ST_XMin(ST_Envelope(ST_Transform(geom, 4326))) ||
    '&right='  || ST_XMax(ST_Envelope(ST_Transform(geom, 4326))) ||
    '&top='    || ST_YMax(ST_Envelope(ST_Transform(geom, 4326))) ||
    '&bottom=' || ST_YMin(ST_Envelope(ST_Transform(geom, 4326))) || ')'    as "Place bounding box",
    now() as debug_created_at -- for debug purposes, will be dropped after problem solved
from res
where rank_by_cnt < 101; --limit to 100 for each country

-- Drop temporary tables
drop table if exists country_boundaries_subdivided_in;
