drop table if exists abu_dhabi_buildings;
create table abu_dhabi_buildings with (parallel_workers = 32) as (
    select *  -- TODO: list of necessary fields
    from abu_dhabi_buildings_phase_1
);

-- TODO: check the uniqueness of ids

delete
from abu_dhabi_buildings b1
where b1.id in (select b2.id
                from abu_dhabi_buildings b2,
                     public.osm_unpopulated u
                where ST_Intersects(ST_Transform(b2.geom, 3857), u.geom));

create index on abu_dhabi_buildings using gist(geom);
