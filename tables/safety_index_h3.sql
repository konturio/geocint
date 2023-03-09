-- Create extraction from kontur_boundaries where hasc in Global RVA data
drop table if exists safety_index_in;
create table safety_index_in as
	select k.kontur_admin_level    as admin_level,
	       k.geom                  as geom,
	       s.gpi2022               as safety_index
	from kontur_boundaries k join
	     safety_index_per_country s
	on s.iso2 = k.hasc_wiki
	where k.hasc_wiki in (select iso2 from safety_index_per_country);

-- remove duplicates with low admin level
drop table if exists safety_index_h3;
create table safety_index_h3  as
	select distinct on (h3) h3_polygon_to_cells(ST_Subdivide(geom), 8) as h3,
	                        safety_index,
	                        8 as resolution
	from safety_index_in
	order by h3, admin_level desc;

-- drop temporary table
drop table if exists safety_index_in;