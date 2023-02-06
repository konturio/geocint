-- Create extraction from kontur_boundaries where hasc in Global RVA data
drop table if exists boundaries_in;
create table boundaries_in as
	select k.kontur_admin_level    as admin_level,
	       k.geom                  as geom,
	       g.mhr_index             as mhr_index,
	       g.mhe_index             as mhe_index,
	       g.resilience_index      as resilience_index,
	       g.coping_capacity_index as coping_capacity_index,
	       g.vulnerability_index   as vulnerability_index
	from kontur_boundaries k join
	     global_rva_normalized_indexes g
	on g.hasc = k.hasc_wiki
	where k.hasc_wiki in (select hasc from global_rva_normalized_indexes);

-- remove duplicates with low admin level
drop table if exists global_rva_normalized_h3;
create table global_rva_normalized_h3  as
	select distinct on (h3) h3_polygon_to_cells(ST_Subdivide(geom), 8) as h3,
	                        mhr_index,
	                        mhe_index,
	                        resilience_index,
	                        coping_capacity_index,
	                        vulnerability_index,
	                        8 as resolution
	from boundaries_in
	order by h3, admin_level desc;

-- drop temporary table
drop table if exists boundaries_in;