drop trigger if exists planet_osm_line_osm2pgsql_valid on planet_osm_line;
drop trigger if exists planet_osm_polygon_osm2pgsql_valid on planet_osm_polygon;

with cte as (select osm_id, 
                    lang
             from (select distinct on (p.osm_id) p.osm_id, 
                                                 p.tags, 
                                                 p.name, 
                                                 default_language as lang
                   from planet_osm_point p join kontur_default_languages c on ST_Intersects(p.way, c.geom)
                   where p.name is not null
                   order by p.osm_id, c.admin_level desc) t
             where not tags ? lang)
update planet_osm_point
set tags = tags || hstore(cte.lang, name) from cte
where cte.osm_id = planet_osm_point.osm_id;

vacuum planet_osm_point;

with cte as (select osm_id, 
                    lang
             from (select distinct on (p.osm_id) p.osm_id, 
                                                 p.tags, 
                                                 p.name, 
                                                 default_language as lang
                   from planet_osm_line p join kontur_default_languages c on ST_Intersects(p.way, c.geom)
                   where p.name is not null
                   order by p.osm_id, c.admin_level desc) t
             where not tags ? lang)
update planet_osm_line
set tags = tags || hstore(cte.lang, name) from cte
where cte.osm_id = planet_osm_line.osm_id;

vacuum planet_osm_line;

with cte as (select osm_id, lang
             from (select distinct on (p.osm_id) p.osm_id, 
                                                 p.tags, 
                                                 p.name, 
                                                 default_language as lang
                   from planet_osm_polygon p join kontur_default_languages c on ST_Intersects(p.way, c.geom)
                   where p.name is not null
                   order by p.osm_id, c.admin_level desc) t
             where not tags ? lang)
update planet_osm_polygon
set tags = tags || hstore(cte.lang, name)
from cte
where cte.osm_id = planet_osm_polygon.osm_id;

vacuum planet_osm_polygon;
