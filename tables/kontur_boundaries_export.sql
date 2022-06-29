drop table if exists kontur_boundaries_export;

create table kontur_boundaries_export as
select k.kontur_admin_level as admin_level,
       k.name,
       k.name_en,
       k.population,
       h.hasc as location,
       k.hasc_wiki as hasc,
       k.geom
from kontur_boundaries k,
     hdx_boundaries h
where ST_Intersects(ST_PointOnSurface(k.geom), h.geom);

create index on kontur_boundaries_export (location);

delete from
    kontur_boundaries_export
where
    location = 'DE' and (name='Uithuizen' or name='Delfzijl');