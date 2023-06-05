drop table if exists boundaries_statistics_report_in;
create table boundaries_statistics_report_in as (
	select coalesce(c.name_en,c.name)                                                               as name,
	       c.osm_admin_level                                                                        as admin_level,
	       c.osm_id,
	       c.osm_type,
	       c.location,
	       c.population,
	       string_agg('href_['||h.id::text||'](https://tasks.hotosm.org/projects/'||h.id::text||')',', ') as projects,
	       st_transform(c.geom, 3857)                                                               as geom
	from kontur_boundaries_export c left join hot_projects h on st_intersects(c.geom, h.geom)
	where c.osm_admin_level::integer <= 5
	group by 1,2,3,4,5,6,8
);


<a href="http://example.com/">http://example.com/</a>

drop table if exists boundaries_geom_prepared;
create table boundaries_geom_prepared as (
    select osm_id,
           ST_Subdivide(geom) as geom
    from boundaries_statistics_report_in
);

create index on boundaries_geom_prepared using gist(geom);

drop table if exists boundaries_statistics_prepared;
create table boundaries_statistics_prepared as (
    select distinct on (osm_id,h3)  b.osm_id,
	                                s.population,
	                                s.area_km2,
	                                s.populated_area_km2,
	                                s.building_count,
	                                s.highway_length,
	                                s.count,
	                                s.hazardous_days_count
    from boundaries_geom_prepared b left join stat_h3 s on st_intersects(b.geom, s.geom)
    where s.resolution = 8
);

drop table if exists boundaries_geom_prepared;

drop table if exists boundaries_statistics_report_mid;
create table boundaries_statistics_report_mid as (
	select s.osm_id,
	       max(hazardous_days_count)                                                                                      as hazardous_days_count,	       
           sum(s.populated_area_km2)                                                                                      as populated_area_km2,
	       sum(s.populated_area_km2*(1-sign(s.highway_length)))                                                           as roads_unmapped_km2,
	       sum(s.population * (1 - sign(s.building_count)))                                                               as people_without_osm_buildings,
	       sum(s.population * (1 - sign(s.highway_length)))                                                               as people_without_osm_roads,
	       sum(s.population * (1 - sign(s.count)))                                                                        as people_without_osm_objects,
	       coalesce((sum(s.populated_area_km2*(1-sign(s.building_count)))/ nullif(sum(s.populated_area_km2), 0))* 100, 0) as buildings_unmapped_percentage,
           coalesce((sum(s.populated_area_km2*(1-sign(s.highway_length)))/ nullif(sum(s.populated_area_km2), 0))* 100, 0) as roads_unmapped_percentage,
           coalesce((sum(s.populated_area_km2 * (1 - sign(s.count))) / nullif(sum(populated_area_km2), 0))* 100, 0)       as osm_gaps_percentage
	from boundaries_statistics_prepared s
	group by 1
);

drop table if exists boundaries_statistics_report;
create table boundaries_statistics_report as (
	select 
	        -- Mark start of the string with subrow_ prefix if needed:
            case when b.admin_level = '2' then '' else 'subrow_' end ||
            -- Generate link to object properties on osm.org:
            coalesce('href_[' || case when b.admin_level = '2' then '' else 'tab_' end 
            || b.name || '](https://www.openstreetmap.org/' ||
            osm_type || '/' || b.osm_id || ')', '')                               as "Name",
            b.admin_level                                                         as "Admin level",
            b.population                                                          as "Population",            
            c.people_without_osm_buildings                                        as "People with no OSM buildings",
            c.people_without_osm_roads                                            as "People with no OSM roads",
            c.people_without_osm_objects                                          as "People with no OSM objects",
            trunc(cast(c.populated_area_km2 as numeric), 3)                       as "Populated area km2",
            trunc(cast(c.osm_gaps_percentage as numeric), 3)                      as "Populated area with no OSM objects %",
            trunc(cast(c.buildings_unmapped_percentage as numeric), 3)            as "Populated area with no OSM buildings %",
            trunc(cast(c.roads_unmapped_percentage as numeric), 3)                as "Populated area with no OSM roads %",
            c.hazardous_days_count                                                as "Hazardous days count",
            b.projects                                                            as "HOT Projects",
            b.location,
            b.admin_level
    from boundaries_statistics_report_in b join boundaries_statistics_report_mid c on c.osm_id=b.osm_id
    order by location, admin_level
);
