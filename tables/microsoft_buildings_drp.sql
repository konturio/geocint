drop table if exists microsoft_buildings_drp;
create table microsoft_buildings_drp as (
    select r.city_name,
           m.ogc_fid as id,
           m.geom
    from microsoft_buildings m
    join drp_regions r on ST_Intersects(m.geom, r.geom)
);

create index microsoft_buildings_drp_city_name_idx on microsoft_buildings_drp (city_name);