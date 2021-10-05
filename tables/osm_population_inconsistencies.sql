-- Extract boundaries with valid population and admin_level tags;
drop table if exists osm_admin_boundaries_in;
create table osm_admin_boundaries_in as
select
       osm_id,
       name,
       admin_level::smallint,
       (tags ->> 'population')::bigint population,
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
       ST_Subdivide(geom) geom
from osm_admin_boundaries_in;
create index on osm_admin_subdivided using gist(geom);


-- Calculate difference between population key value and Sum of child boundaries population
drop table if exists osm_admin_hierarchy;
create table osm_admin_hierarchy as
-- Find upper admin_level of children for every boundary
with child_level as(
        select
               s.osm_id,
               (array_agg(b.admin_level order by b.admin_level asc))[1] child_level
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
       array_agg(b.osm_id order by b.osm_id asc) filter(where b.admin_level = c.child_level) children
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
    select row_number() over() id, *                                     -- enumerate rows for proper sorting further
    from (
        select unnest(array_prepend(osm_id, children)) osm_id
        from (select * from osm_admin_hierarchy order by pop_diff_percent desc) a
    ) b
)
select
       id,
       h1.osm_id::text                                                   as "OSM ID",
       repeat(' ', b.admin_level) ||                                     -- greater admin_level -> more spaces tabulation before name
           case
               when h2.name is null then '-' || b.name                   -- if the boundary itself has population inconsistency error then it's name starts without dash
               else b.name                                               -- otherwise with dash
           end                                                           as "Name",
       b.admin_level                                                     as "Admin level",
       coalesce(b.population::text, '-')                                 as "Population",
       coalesce(h2.c_sum_pop::text, '-')                                 as "SUM subregions population",
       coalesce('+' || h2.pop_diff::text, '-')                           as "Population difference value",
       coalesce('+' || round(h2.pop_diff_percent, 1)::text, '-')         as "Population difference %"
from unnested h1
left join osm_admin_hierarchy h2 using(osm_id)
left join osm_admin_boundaries_in b using(osm_id);


-- Drop unnecessary tables
drop table if exists osm_admin_boundaries_in;
drop table if exists osm_admin_subdivided;
drop table if exists osm_admin_hierarchy;
