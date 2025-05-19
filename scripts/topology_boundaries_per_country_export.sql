-- this script is modification of tables/topology_boundaries.sql
-- topology_boundaries.sql produces duplicates for maritime=true segments
-- in this script it was fixed

drop table if exists :tab_temp;

create table :tab_temp as (
    select  row_number() OVER () as id,
            k.kontur_admin_level as admin_level,
            false as maritime,
            (ST_DumpSegments(ST_Transform(ST_Boundary((ST_DumpRings((ST_Dump(k.geom)).geom)).geom), 3857))).geom as geom
    from kontur_boundaries k,
         hdx_boundaries h
    where kontur_admin_level is not null
            and geometrytype(k.geom) ~* 'polygon'
            and h.hasc = :'cnt_code'
            and ST_Intersects(ST_PointOnSurface(k.geom), h.geom)
);

create index on :tab_temp using gist(geom);

-- upd maritime boundaries
update :tab_temp as tab_in
set maritime = true
where exists(select from water_polygons_vector 
    where ST_Intersects(tab_in.geom, water_polygons_vector.geom));

-- select distinct segments
with del as (delete from :tab_temp
    returning *)
insert into :tab_temp(id, admin_level, maritime, geom)
select min(id), min(admin_level), bool_or(maritime), geom
from (select ST_Normalize(geom) as geom, id, admin_level, maritime
    from del) as squ
group by geom;

drop table if exists :tab_result;

create table :tab_result as (
    select  row_number() OVER () as id,
            a.admin_level,
            a.maritime,
            a.geom
    from (select admin_level,
            maritime,
            (ST_Dump(ST_LineMerge(ST_Union(geom)))).geom as geom
    from :tab_temp
    group by admin_level, maritime) a order by admin_level
);

drop table if exists :tab_temp;
