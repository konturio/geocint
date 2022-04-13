-- Create extraction from kontur_boundaries where hasc in Global RVA data
drop table if exists boundaries_in;
create table boundaries_in as
	select hasc_wiki          as hasc,
	       kontur_admin_level as admin_level,
	       geom               as geom
	from kontur_boundaries
	where hasc_wiki in ('RU','FK','KP','DK','SI','SN','PN','CZ','KR','VE','BS','MH','AU','QA','MZ','EE','VN','TD','NF',
		                'KW','AR','MG','BR','BV','RW','NA','PL','VU','MC','VC','GI','EG','TT','MU','NU','HU','FI','WF',
		                'ST','NR','EC','KG','AO','MR','IE','DJ','BD','AQ','ES','TH','BA','TN','AL','GS','VA','GF','MM',
		                'PY','US','SG','CK','KE','YE','UG','LY','NZ','GU','DM','IN','CN','NE','BN','ME','ET','MY','MV',
		                'MQ','VG','SE','SB','GH','CH','BT','PW','PK','LU','BO','FM','ML','LV','FJ','PG','RO','TZ','BI',
		                'SO','ZW','ER','LC','CG','FO','GA','MN','GY','WS','PA','LB','MD','PT','TO','UM','NG','CC','IL',
		                'GB','IT','GP','CR','MK','GR','BJ','CM','GW','CX','TK','TF','SV','JP','UZ','TL','TV','CL','GE',
		                'BM','AT','LI','CI','NI','TJ','LR','BZ','YT','LA','MT','BY','EH','LK','SA','SM','DE','SK','SJ',
		                'SS','LT','JM','SH','SR','CY','PF','BB','SZ','AG','RS','TM','TG','JE','RE','UA','DO','NO','TR',
		                'PS','BH','CU','MA','SY','CO','BE','DZ','PM','AS','AZ','GL','GT','PE','KZ','SL','UY','AE','HN',
		                'IQ','IR','CF','NL','GQ','GM','ZM','LS','CD','SD','TC','HK','KM','IO','NP','BW','MP','AI','KN',
		                'BF','SC','VI','AW','CA','PR','FR','KY','MX','GG','MS','PH','NC','IM','ID','OM','AM','KI','AF',
		                'HT','ZA','AD','GN','JO','BG','IS','HR','KH','MW','HM','GD','CV','BQ');

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