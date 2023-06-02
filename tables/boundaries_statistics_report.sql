drop table if exists boundaries_statistics_report_in;
create table boundaries_statistics_report_in as (
	select coalesce(name_en,name) as name,
	       osm_admin_level         as admin_level,
	       osm_id,
	       osm_type,
	       location,
	       population,
	       geom
	from kontur_boundaries_export
	where osm_admin_level::integer <= 5
);

drop table if exists boundaries_statistics_report;
create table boundaries_statistics_report as (
	select 
	        -- Mark start of the string with subrow_ prefix if needed:
            case when admin_level = '2' then '' else 'subrow_' end ||
            -- Generate link to object properties on osm.org:
            coalesce('href_[' || case when admin_level = '2' then '' else 'tab_' end 
            || name || '](https://www.openstreetmap.org/' ||
            osm_type || '/' || osm_id || ')', '')                               as "Name",
            admin_level                                                         as "Admin level",
            population                                                          as "Population",
            location,
            admin_level
    from boundaries_statistics_report_in
    order by location, admin_level
);
