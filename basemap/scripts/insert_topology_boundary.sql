insert into planet_osm_line (osm_id, 
	                         boundary, 
	                         admin_level, 
	                         maritime, 
	                         way, 
	                         tags) 
    select -osm_id as osm_id, 
           'administrative' as boundary, 
           admin_level, 
           nullif(maritime, false), 
           geom as way, 
           hstore('name:'||default_language, name) as tags
    from kontur_topology_boundary;

set max_parallel_maintenance_workers = 0;
vacuum planet_osm_line;
set max_parallel_maintenance_workers = 2;