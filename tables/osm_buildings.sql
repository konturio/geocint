drop table if exists osm_buildings;

create table osm_buildings as (
    select osm_type,
           osm_id,
           tags ->> 'building'         as building,
           tags ->> 'addr:street'      as street,
           tags ->> 'addr:housenumber' as hno,
           tags ->> 'building:levels'  as levels,
           tags ->> 'height'           as height,
           tags ->> 'building:use'     as use,
           tags ->> 'name'             as name,
           geog::geometry              as geom
    from osm o
    where tags ? 'building'
);

update osm_buildings b
set use = 'school'
from (select tags ->> 'amenity=school' as school,
             geog::geometry            as geom
      from osm) as s
where ST_Intersects(s.geom, b.geom);

update osm_buildings b
set use = 'hospital'
from (select tags ->> 'amenity=hospital' as school,
             geog::geometry              as geom
      from osm) as h
where ST_Intersects(h.geom, b.geom);

update osm_buildings b
set use = 'university'
from (select tags ->> 'amenity=university' as university,
             geog::geometry                as geom
      from osm) as u
where ST_Intersects(u.geom, b.geom);

update osm_buildings b
set use = 'garage'
from (select tags ->> 'landuse=garages' as garage,
             geog::geometry             as geom
      from osm) as g
where ST_Intersects(g.geom, b.geom);

update osm_buildings b
set use = 'house'
from (select tags ->> 'landuse=residential ' as residential,
             tags ->> 'residential=rural'    as rural,
             geog::geometry                  as geom
      from osm) as ho
where ST_Intersects(ho.geom, b.geom);

update osm_buildings b
set use = 'apartments'
from (select tags ->> 'landuse=residential' as residential,
             tags ->> 'residential=urban'   as urban,
             geog::geometry                 as geom
      from osm) as a
where ST_Intersects(a.geom, b.geom);

update osm_buildings b
set use = 'industrial'
from (select tags ->> 'landuse=industrial' as industrial,
             geog::geometry                as geom
      from osm) as i
where ST_Intersects(i.geom, b.geom);

update osm_buildings b
set use = 'office'
from (select tags ->> 'office' as office,
             geog::geometry    as geom
      from osm) as of
where ST_Intersects(of.geom, b.geom);

update osm_buildings b
set use = 'industrial'
from (select tags ->> 'power' as power,
             geog::geometry   as geom
      from osm) as p
where ST_Intersects(p.geom, b.geom);

update osm_buildings b
set use = 'commercial'
from (select tags ->> 'landuse=commercial' as commercial,
             geog::geometry   as geom
      from osm) as c
where ST_Intersects(c.geom, b.geom);

update osm_buildings b
set use = 'retail'
from (select tags ->> 'landuse=retail' as retail,
             geog::geometry   as geom
      from osm) as r
where ST_Intersects(r.geom, b.geom);

update osm_buildings b
set use = 'commercial'
from (select tags ->> 'landuse=commercial' as commercial,
             geog::geometry   as geom
      from osm) as c
where ST_Intersects(c.geom, b.geom);

