drop table if exists gadm_us_counties_boundary;
create table gadm_us_counties_boundary as (
	select a.name as name_1, 
	       b.name as name_2, 
	       b.gid  as gid_2, 
	       b.hasc as hasc_2,
	       b.geom as geom
	from gadm_boundaries a, 
	     gadm_boundaries b 
	where b.hasc like a.hasc || '%' 
	      and a.gid_0 = 'USA' 
	      and b.gid_0 = 'USA' 
	      and a.hasc != b.hasc
	union all
	select 'Puerto Rico' as name_1,
	       name          as name_2,
	       gid           as gid_2,
	       hasc          as hasc_2,
	       geom          as geom
	from gadm_boundaries 
	where gid_0 = 'PRI'
);

create index on gadm_us_counties_boundary using gist(geom);
create index on gadm_us_counties_boundary using btree(hasc_2);
