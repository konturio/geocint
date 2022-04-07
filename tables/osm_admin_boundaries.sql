drop table if exists osm_admin_boundaries;
create table osm_admin_boundaries as (
    select osm_id,
           osm_type,
           tags ->> 'boundary'    as boundary,
           tags ->> 'admin_level' as admin_level,
           tags ->> 'name'        as "name",
           tags,
           ST_Normalize(geog::geometry)         as geom
    from osm
    where (
            tags ? 'admin_level'
        and tags @>
            '{"boundary":"administrative"}'
        and ST_Dimension(geog::geometry) = 2
        and not (tags ->> 'name' is null and tags @> '{"admin_level":"2"}')
    )
       or tags @> '{"ISO3166-1":"PS"}' -- Special rule for Palestinian Territories - because of it's disputed status it often lacks admin_level key
    order by osm_id
);

create index on osm_admin_boundaries using gist(geom);
create index on osm_admin_boundaries (osm_id);
create index on osm_admin_boundaries using gist(ST_PointOnSurface(geom));

-- faster than checking st_equals and deleting, 
-- also there is hope that it uses index
drop table if exists osm_admin_boundaries_duplicates;
create table osm_admin_boundaries_duplicates as
select  a.osm_id, b.osm_id as osm_id2, a.geom as g1, b.geom as g2
from    osm_admin_boundaries a,
        osm_admin_boundaries b
where   a.osm_id > b.osm_id and 
    a.geom = b.geom;

delete from osm_admin_boundaries
where osm_id in (select osm_id from osm_admin_boundaries_duplicates);

drop table if exists osm_admin_boundaries_duplicates;


-- generating parent_id for admin_level > 2 
-- parent_id points to it's country
drop table if exists osm_admin_cnt_subdivided_in;

create table osm_admin_cnt_subdivided_in as
select  osm_id,
        ST_Subdivide(geom) as geom
from    osm_admin_boundaries
where   admin_level ~E'^\\d+$'
        and admin_level::int = 2;

create index on osm_admin_cnt_subdivided_in using gist(geom);

drop table if exists osm_admin_lvls_in;
create table osm_admin_lvls_in as
select  b.osm_id,
        p.osm_id as parent_id,
        replace(b.admin_level, '2.5', '3')::int as admin_level,
        ST_Area(b.geom::geography) as area_geom,
        replace(b.admin_level, '2.5', '3')::int as kontur_admin_level
from        osm_admin_boundaries as b
LEFT JOIN   osm_admin_cnt_subdivided_in as p
ON          st_intersects(ST_PointOnSurface(b.geom), p.geom)
where   replace(b.admin_level,'2.5', '3') ~* '^\d+$' and 
        replace(b.admin_level,'2.5', '3')::int > 2;

-- fix for lvls without parent_id
update osm_admin_lvls_in
set parent_id = (select max(parent_id) + 1 from osm_admin_lvls_in where parent_id is not null)
where parent_id is null;

-- here happens rearangment of level within country
-- some countries has lvl=3 smaller by area than lvl>3
-- after this they switch places
with oldsort as (select parent_id, kontur_admin_level,
        avg(area_geom) as ar
    from osm_admin_lvls_in
    group by parent_id, kontur_admin_level),
newsort as (select parent_id,
        array_agg(distinct kontur_admin_level order by kontur_admin_level) as levels
    from oldsort
    group by parent_id), 
toup as (select oldsort.parent_id, kontur_admin_level, levels,
    -- new order by avg(area_geom) desc
    dense_rank() over(partition by oldsort.parent_id order by ar desc, kontur_admin_level) as id2
    from oldsort, newsort
    where oldsort.parent_id = newsort.parent_id)
update osm_admin_lvls_in as o
set kontur_admin_level = levels[id2]
from toup
where o.parent_id = toup.parent_id
    and o.kontur_admin_level = toup.kontur_admin_level;

do
$$
    declare 
        var_lvl int;
    begin
        for var_lvl in  select distinct kontur_admin_level 
                        from osm_admin_lvls_in 
                        where kontur_admin_level between 2 and 8
                        order by 1 
        loop
	        with qwrld as (select   kontur_admin_level, 
                                    -- avg(area_geom) as avg_area_in_world, --was used for v1, can be switched back
                                    percentile_cont(0.8) within group (order by area_geom) as avg_area_in_world
                from osm_admin_lvls_in
                group by 1
                order by 1),
            qcnt as (select   parent_id, kontur_admin_level,
                            -- avg(area_geom) as avg_area_in_cnt --switch here also
                            percentile_cont(0.5) within group (order by area_geom) as avg_area_in_cnt
                from    osm_admin_lvls_in
                where   kontur_admin_level = var_lvl
                group by    parent_id, kontur_admin_level),
            -- in next query I use abs(avg_area_in_world - avg_area_in_cnt) - to take the closest admin_level by area similarity
            qres as (select   distinct on (qcnt.parent_id, qcnt.kontur_admin_level)
                                qcnt.parent_id, qcnt.kontur_admin_level, qwrld.kontur_admin_level as nadm_lvl, 
                                abs(avg_area_in_world - avg_area_in_cnt)
                from    qcnt, qwrld
                order by    qcnt.parent_id, qcnt.kontur_admin_level, abs(avg_area_in_world - avg_area_in_cnt) ),
            -- with new admin_level I need firstly update levels in other levels to prevent overlapping
            -- if new lvl = 4 I need to move all levels from 4 to .. +1 
            upchild as (update    osm_admin_lvls_in as o
                set     kontur_admin_level = o.kontur_admin_level + 1
                from qres
                where   o.parent_id = qres.parent_id 
                    and qres.kontur_admin_level < qres.nadm_lvl --check is it going to update in next step?
                    and o.kontur_admin_level > qres.kontur_admin_level --update all levels bigger than new
                returning 1)
            update  osm_admin_lvls_in as o
            set     kontur_admin_level = GREATEST(qres.kontur_admin_level, qres.nadm_lvl) --sometimes nadm_lvl=3 and klvl=4, this prevents overlapping
            from    qres
            where   o.parent_id = qres.parent_id
                    and o.kontur_admin_level = qres.kontur_admin_level
                   	and qres.kontur_admin_level >= qres.nadm_lvl;
        end loop;
    end; 
$$;

alter table osm_admin_boundaries add column kontur_admin_level int;

update  osm_admin_boundaries as o
set     kontur_admin_level = u.kontur_admin_level
from    osm_admin_lvls_in as u
where   o.osm_id = u.osm_id;

-- update kontur_admin_level for countries
update  osm_admin_boundaries as o
set     kontur_admin_level = 2
where 	admin_level = '2';

-- kontur_admin_level is null for all objects with errors in admin_level (f.e. text value in admin_level)
-- i left this on purpose, it is discussable 

drop table if exists osm_admin_cnt_subdivided_in;
drop table if exists osm_admin_lvls_in;