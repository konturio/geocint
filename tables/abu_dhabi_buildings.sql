-- FIXME: rewrite, waiting for merge #6671
drop table if exists abu_dhabi_buildings;
create table abu_dhabi_buildings with (parallel_workers = 32) as (
    select distinct osm_id,
                    coalesce(height, levels * 3) as height,
                    use,
                    b.name,
                    tags,
                    b.geom
    from osm_buildings b,
         abu_dhabi_admin_boundaries a
    where ST_Intersects(b.geom, a.geom)
      and osm_type = 'relation'
      and (height is not null or levels is not null)
);

create index on abu_dhabi_buildings using gist (geom);