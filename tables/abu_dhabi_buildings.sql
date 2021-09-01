drop table if exists abu_dhabi_buildings;
create table abu_dhabi_buildings with (parallel_workers = 32) as (
    select osm_landuse_class,
           is_residential,
           shape_type,
           processing_date,
           building_height,
           id,
           ST_Union(geom) as geom
    from abu_dhabi_buildings_phase_1
    group by osm_landuse_class, is_residential, shape_type, processing_date, building_height, id
);

delete
from abu_dhabi_buildings b1
where b1.id in (
    select b2.id
    from abu_dhabi_buildings b2,
         osm_water_polygons u
    where ST_Intersects(ST_Transform(b2.geom, 3857), u.geom)
);

create index on abu_dhabi_buildings using gist (geom);
