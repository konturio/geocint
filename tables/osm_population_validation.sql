-- Subdivide OSM boundaries to speed up spatial joins when building subregions hierarchy
drop table if exists osm_admin_subdivided;
create table osm_admin_subdivided as
select osm_id, admin_level, ST_Subdivide(geom) geom
from osm_admin_boundaries;
create index on osm_admin_subdivided using gist(geom);

select count(*) from osm_admin_hierarchy;
-- Build subregions hierarchy to sum subregions population
drop table if exists osm_admin_hierarchy;
create table osm_admin_hierarchy as
select
       b.osm_id,
       b.name,
       b.tags ->> 'name:en' name_en,
       b.admin_level::int,
       case
           when b.tags ->> 'population' ~ '^\d+$' -- Check whether population value is integer
               then (b.tags ->> 'population')::bigint
       end as population,
       array_agg(s.osm_id order by s.admin_level::int asc) parents
from osm_admin_boundaries b
left join osm_admin_subdivided s
    on ST_Intersects(ST_PointOnSurface(b.geom), s.geom)
        and s.admin_level ~ '^\d{1,2}$'            -- Check whether population value is integer
        and b.admin_level::int >= s.admin_level::int
where b.admin_level ~ '^\d{1,2}$'
        and b.tags ->> 'population' ~ '^\d+$'
group by
         b.osm_id,
         b.name,
         name_en,
         b.admin_level,
         population;
create index on osm_admin_hierarchy using gin(parents);


--Calculate absolute position in admin_level hierarchy for every boundary
--to use it for sum(population) of subregions further
drop table if exists hierarchy_position;
create table hierarchy_position as
        select c.osm_id, max(array_position(l.parents, c.osm_id))  as max_position
        from osm_admin_hierarchy c
        left join osm_admin_hierarchy l
                on array[c.osm_id] <@ l.parents                    -- to use gin index on parents[] array field
        group by c.osm_id;


--Sum populaion of subregions for every boundary
--and compare it with population from OSM key (if any)
drop table if exists osm_population_validation;
create table osm_population_validation as
select
       h.osm_id::text                                              as "OSM ID",
       h.name                                                      as "Name",
       h.name_en                                                   as "Name En",
       h.admin_level                                               as "Admin level",
       h.population                                                as "Population from OSM key",
       sum(s.population)                                           as "SUM subregions population",
       (sum(s.population) - h.population)  * 100 / h.population    as "Population difference %"
from osm_admin_hierarchy h
left join hierarchy_position p using(osm_id)
left join osm_admin_hierarchy s
        on array[h.osm_id] <@ s.parents                            -- to use gin index on parents[] array field
               and array_length(s.parents, 1) - 1 = p.max_position -- max position = position of boundary itself
               and h.osm_id <> s.osm_id
where h.population > 0
group by 1,2,3,4,5
having sum(s.population) - h.population > 0;


--Drop temporary tables
drop table if exists osm_admin_subdivided;
drop table if exists osm_admin_hierarchy;
drop table if exists hierarchy_position;

