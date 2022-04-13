-- Create extraction from kontur_boundaries where hasc in Global RVA data
drop table if exists boundaries_in;
create table boundaries_in as
	select hasc_wiki          as hasc,
	       kontur_admin_level as admin_level,
	       geom               as geom
	from kontur_boundaries
	where hasc_wiki in (select hasc from global_rva_indexes);

-- generate h3 grid for every boundary:
drop table if exists boundaries_h3_in;
create table boundaries_h3_in as
    select  h3_polyfill(ST_Subdivide(geom), 8) as h3,
            admin_level,
            hasc
    from boundaries_in;

-- drop temporary table
drop table if exists boundaries_in;

-- remove duplicates with low admin level
drop table if exists boundaries_h3_mid;
create table boundaries_h3_mid as
	select distinct on (h3) h3,
	                        hasc
	from boundaries_h3_in
	order by admin_level desc;
create index on boundaries_h3_mid using gin(hasc);

-- drop temporary table
drop table if exists boundaries_h3_in;

-- Create table with pdc data joined with hexs by hasc
drop table if exists global_rva_h3;
create table global_rva_h3 as
	select b.h3,
	       8                       as resolution,
	       g.mhr_index             as mhr_index,
	       g.mhe_index             as mhe_index,
	       g.resilience_index      as resilience_index,
	       g.coping_capacity_index as coping_capacity_index,
	       g.vulnerability_index   as vulnerability_index
	       from global_rva_indexes g,
	            boundaries_h3_mid b
	       where g.hasc = b.hasc;

-- drop temporary table
drop table if exists boundaries_h3_mid;