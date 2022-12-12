with cte as (select osm_id, lang
             from (select distinct
                   on (p.osm_id) p.osm_id, tags, p.name, lang
                   from planet_osm_point p join countries c
                   on ST_Intersects(p.way, c.geom)
                   where p.name is not null
                   order by p.osm_id, c.geom) t
             where not tags ? lang)
update planet_osm_point
set tags = tags || hstore(cte.lang, name) from cte
where cte.osm_id = planet_osm_point.osm_id;


with cte as (select osm_id, lang
             from (select distinct
                   on (p.osm_id) p.osm_id, tags, p.name, lang
                   from planet_osm_line p join countries c
                   on ST_Intersects(p.way, c.geom)
                   where p.name is not null
                   order by p.osm_id, c.geom) t
             where not tags ? lang)
update planet_osm_line
set tags = tags || hstore(cte.lang, name) from cte
where cte.osm_id = planet_osm_line.osm_id;


with cte as (select osm_id, lang
             from (select distinct
                   on (p.osm_id) p.osm_id, tags, p.name, lang
                   from planet_osm_polygon p join countries c
                   on ST_Intersects(p.way, c.geom)
                   where p.name is not null
                   order by p.osm_id, c.geom) t
             where not tags ? lang)
update planet_osm_polygon
set tags = tags || hstore(cte.lang, name)
from cte
where cte.osm_id = planet_osm_polygon.osm_id;