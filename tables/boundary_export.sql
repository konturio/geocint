-- Match high level kontur_boundaries with HASC codes by wikidata identifier
drop table if exists hasc_boundaries;
create table hasc_boundaries as
select h.hasc,
       b.geom
from kontur_boundaries b
left join hasc_location h
        on wikicode = b.tags ->> 'wikidata';

create index on hasc_boundaries using gist(geom);

-- Extract data from kontur_boundaries and assign high level hasc codes
drop table if exists boundary_export;
create table boundary_export as
select k.kontur_admin_level as admin_level,
       k.name, 
       k.name_en, 
       k.population,
       k.geom,
       h.hasc as location,
       k.hasc_wiki as hasc
from kontur_boundaries k,
     hasc_boundaries h
     where ST_Intersects(ST_PointOnSurface(k.geom), h.geom);