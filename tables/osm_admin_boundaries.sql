drop table if exists osm_admin_boundaries_in;
create table osm_admin_boundaries_in as (
    select osm_id,
           osm_type,
           tags ->> 'boundary'    as boundary,
           tags ->> 'admin_level' as admin_level,
           tags ->> 'name'        as "name",
           tags,
           geog::geometry         as geom
    from osm
    where tags ? 'admin_level'
      and tags @>
          '{"boundary":"administrative"}'
      and ST_Dimension(geog::geometry) = 2
      and not (tags ->> 'name' is null and tags @> '{"admin_level":"2"}')
);

create index on osm_admin_boundaries_in using gist(geom);

delete from osm_admin_boundaries_in a
using osm_admin_boundaries_in b
where a.osm_id > b.osm_id and ST_Equals(a.geom, b.geom);


-- Prepare subdivided osm admin boundaries table with index for further queries
drop table if exists osm_admin_subdivided;
create table osm_admin_subdivided as
select
        osm_id,
        ST_Subdivide(ST_Transform(geom, 3857)) as geom
from osm_admin_boundaries_in;
create index on osm_admin_subdivided using gist(geom);


-- Sum population from h3 to osm admin boundaries
drop table if exists osm_admin_boundaries;
create table osm_admin_boundaries as
with sum_population as (
		select 
		        b.osm_id,
		        sum(h.population * 
	                    (case
	                        when ST_Within(h.geom, b.geom)
	                            then 1
	                        else ST_Area(ST_Intersection(h.geom, b.geom)) / ST_Area(h.geom)
	                    end) -- Calculate intersection area for each h3 cell and boundary polygon 
		        ) as population
		from osm_admin_subdivided b
		join kontur_population_h3 h
		        on ST_Intersects(h.geom, b.geom)
		where h.resolution = 8
		and h.population > 0
		group by b.osm_id
)
select
        b.osm_id,
        b.osm_type,
        b.boundary,
        b.admin_level,
        b.name,
        b.tags,
        p.population,
        b.geom 
from osm_admin_boundaries_in b 
left join sum_population p using(osm_id);


-- Drop temporary table
drop table if exists osm_admin_boundaries_in;
drop table if exists osm_admin_subdivided;

