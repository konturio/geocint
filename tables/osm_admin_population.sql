-- Prepare subdivided osm admin boundaries table with indexes for further queries
drop table if exists osm_admin_subdivided;
create table osm_admin_subdivided as
select
	osm_id,
	name,  --debug
	admin_level::int,
	st_subdivide(geom) geom
from osm_admin_boundaries
where admin_level in ('1','2','3','4','5','6','7','8','9','10','11','12'); --filtering out incorrect values from OSM --6m
create index on osm_admin_subdivided(admin_level); --5s
create index on osm_admin_subdivided using gist(geom); --1m


-- Joining h3 population dataset with osm admin boundaries
drop table if exists osm_admin_h3_r8;
create table osm_admin_h3_r8 as
--explain
select
	h.h3,
	h.resolution,
	b.osm_id,
	b.admin_level,
	h.population,
	h.area
from osm_admin_subdivided b
join h3 h
	on st_dwithin(h.h3::geometry, b.geom, 0)
		and h.resolution = 8;
create index on osm_admin_h3_r8(population);
create index on osm_admin_h3_r8(osm_id);


-- Sum population from h3 to osm admin boundaries 
drop table if exists osm_admin_population;
create table osm_admin_population as 
select 
	b.osm_id,
	b.admin_level::int,
	b.name,
	sum(h.population) kontur_population,
	b.geom
from osm_admin_boundaries b 
left join osm_admin_h3_r8 h using(osm_id)
where b.admin_level in ('1','2','3','4','5','6','7','8','9','10','11','12') --filtering out incorrect values from OSM --6m
group by b.osm_id, b.admin_level, b.name, b.geom;




