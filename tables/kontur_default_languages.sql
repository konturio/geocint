drop table if exists  kontur_default_languages;
create table kontur_default_languages as (
	-- select default language for all relations from kontur boundaries
	-- mark is_extrapolated 1 for relations, where default_language was set by intersection (doesn't exist as a tag)
	select  osm_id, 
	        default_language, 
	        case 
	            when osm_id in (select osm_id from boundaries_with_default_language) then 0 
	            else 1 
	        end as is_extrapolated, 
	        geom 
	from kontur_boundaries
	union all
	-- add default language for relations which we use to set default language in kontur boundaries, 
	-- but canno't add to kontur_boundaries, for example - language province
	select osm_id, 
	       default_language, 
	       0 as is_extrapolated, 
	       geom 
	from boundaries_with_default_language
	where osm_id not in (select osm_id from kontur_boundaries));

vacuum analyze kontur_default_languages;