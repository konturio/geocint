-- Collect multiple GADM dataset levels together
drop table if exists gadm_boundaries;
create table gadm_boundaries as 
select
		gid_0 gid,
		0::smallint gadm_level,
		null::text hasc, -- GADM level_0 doesn't have HASC codes
		name_0 "name",
		geom
from gadm_level_0
union all 
select
		gid_0 gid,
		1::smallint gadm_level,
		hasc_1 hasc,
		name_1 "name",
		geom
from gadm_level_1
union all
select
		gid_0 gid,
		2::smallint gadm_level,
		hasc_2 hasc,
		name_2 "name",
		geom
from gadm_level_2
union all
select
		gid_0 gid,
		3::smallint gadm_level,
		hasc_3 hasc,
		name_3 "name",
		geom
from gadm_level_3;

create index on gadm_boundaries using gist(geom);
create index on gadm_boundaries using gist(ST_PointOnSurface(geom));
