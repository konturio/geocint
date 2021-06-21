drop table if exists osm_buildings_drp;
create table osm_buildings_drp as (
    select r.city_name,
           b.building,
           b.street,
           b.hno,
           b.levels,
           b.height,
           b.use,
           b."name",
           b.geom
    from osm_buildings b
    join drp_regions r on ST_Intersects(b.geom, r.geom)
    where ST_Dimension(b.geom) != 1
);

create index osm_buildings_drp_city_name_idx on osm_buildings_drp (city_name);