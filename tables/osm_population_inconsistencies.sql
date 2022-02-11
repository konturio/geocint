-- Extract boundaries with valid population and admin_level tags;
drop table if exists osm_admin_boundaries_in;
create table osm_admin_boundaries_in as
select
       osm_id,
       osm_type,
       coalesce(tags ->> 'name:en', tags ->> 'int_name', name) as "name",   -- We want english names first in the reports
       admin_level::smallint                                   as admin_level,
       (tags ->> 'population')::bigint population,
       (tags ->> 'population:date') population_date,
       (tags ->> 'source:population') population_source,
       geom
from osm_admin_boundaries
where tags ->> 'population' ~ '^\d+$'
        and admin_level ~ '^\d{1,2}$';


-- Subdivide OSM boundaries to speed up spatial joins when building subregions hierarchy
drop table if exists osm_admin_subdivided;
create table osm_admin_subdivided as
select
       osm_id,
       admin_level,
       name,
       population,
       population_date,
       population_source,
       ST_Subdivide(geom) as geom
from osm_admin_boundaries_in;
create index on osm_admin_subdivided using gist(geom);


-- Calculate difference between population key value and Sum of child boundaries population
drop table if exists osm_admin_hierarchy;
create table osm_admin_hierarchy as
-- Find upper admin_level of children for every boundary
with child_level as(
        select
               s.osm_id,
               (array_agg(b.admin_level order by b.admin_level))[1] child_level
        from osm_admin_subdivided s
        join osm_admin_boundaries_in b
                on ST_Intersects(s.geom, ST_PointOnSurface(b.geom))
                        and b.admin_level > s.admin_level
        group by s.osm_id
)
-- SUM children population
select
       s.osm_id,
       s.admin_level,
       s.name,
       s.population,
       sum(b.population) filter(where b.admin_level = c.child_level) c_sum_pop,
       sum(b.population) filter(where b.admin_level = c.child_level) - s.population pop_diff,
       sum(b.population) filter(where b.admin_level = c.child_level) / s.population * 100 - 100 pop_diff_percent,
       array_agg(b.osm_id order by b.osm_id) filter(where b.admin_level = c.child_level) children
from osm_admin_subdivided s
join child_level c using (osm_id)
join osm_admin_boundaries_in b
        on ST_Intersects(s.geom, ST_PointOnSurface(b.geom))
                and b.admin_level > s.admin_level
group by s.osm_id, s.admin_level, s.population, s.name
having sum(b.population) filter(where b.admin_level = c.child_level) > s.population;


-- Generate final report table
drop table if exists osm_population_inconsistencies;
create table osm_population_inconsistencies as
with unnested as (
    select
           unnest(array_prepend(osm_id, children)) osm_id,
           osm_id group_id,
           admin_level,
           name,
           population,
           c_sum_pop,
           pop_diff,
           pop_diff_percent
    from (
        select *
        from osm_admin_hierarchy
        order by admin_level, pop_diff_percent desc
    ) a
)
select
        -- Generic id for proper sorting while further export to CSV:
        row_number() over(
            order by u.admin_level, u.pop_diff desc, (u.group_id = u.osm_id) desc, o.name
        )                                                                                   as id,

        -- Mark start of the string with subrow_ prefix if needed:
        case when u.group_id = u.osm_id then '' else 'subrow_' end ||
        -- Generate link to object properties on osm.org:
        coalesce('href_[' || u.osm_id || '](https://www.openstreetmap.org/' ||
        o.osm_type || '/' || u.osm_id || ')', '')                                           as "OSM id",

        -- Generate link for JOSM remote desktop:
        'hrefIcon_[' || case when u.group_id = u.osm_id then '' else 'tab_' end  ||
        o.name || '](http://localhost:8111/load_object?new_layer=false&objects=' ||
        left(o.osm_type, 1) || u.osm_id || '&relation_members=true)'                        as "Name",

        o.admin_level                                                                       as "Admin level",
        o.population                                                                        as "Population",
        o.population_date                                                                   as "Population date",
        o.population_source                                                                 as "Population source",
        case when u.group_id = u.osm_id  then u.c_sum_pop end                               as "SUM subregions population",
        case when u.group_id = u.osm_id  then u.pop_diff  end                               as "Population difference value",
        case when u.group_id = u.osm_id  then round(u.pop_diff_percent, 4) end              as "Population difference %"
from unnested u
left join osm_admin_boundaries_in o using(osm_id)
order by u.admin_level, u.pop_diff desc, (u.group_id = u.osm_id) desc, o.name;


-- Drop unnecessary tables
drop table if exists osm_admin_boundaries_in;
drop table if exists osm_admin_subdivided;
drop table if exists osm_admin_hierarchy;


-- Update timestamp in reports table (for further export to reports API JSON):
update osm_reports_list
set last_updated = (select meta->'data'->'timestamp'->>'last' as updated from osm_meta)
where id = 'osm_population_inconsistencies';