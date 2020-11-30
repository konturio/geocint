-- change schema to match the one expected by consumers
alter table morocco_buildings
    alter column geom type geometry;
alter table morocco_buildings
    drop column fid;
alter table morocco_buildings
    drop column _block_id;
alter table morocco_buildings
    drop column shape_type;
alter table morocco_buildings
    drop column osm_landuse_class;
alter table morocco_buildings
    drop column sun_azimuth;
alter table morocco_buildings
    drop column sun_elevation;
alter table morocco_buildings
    drop column sat_azimuth;
alter table morocco_buildings
    drop column sat_elevation;
alter table morocco_buildings
    drop column processing_date;
alter table morocco_buildings
    rename column _height_confidence to height_confidence;

-- convert multipolygons to polygons
update morocco_buildings
set geom = ST_CollectionHomogenize(geom);

-- make geom robust to conversion to mercator
update morocco_buildings
set geom = ST_CollectionExtract(ST_MakeValid(geom), 3)
where not ST_IsValid(ST_Transform(geom, 3857));

update morocco_buildings_date
set imagery_vintage = '2020-08'
where imagery_vintage is null;

drop table morocco_buildings_date;
create table morocco_buildings_date as (
    select m.*,
           n.date as imagery_vintage
    from morocco_buildings m
             left join morocco_meta_finished_november_2020 n
                       on ST_Intersects(wkb_geometry, ST_PointOnSurface(geom))
);

alter table morocco_buildings_date
    add column height_is_valid bool;
update morocco_buildings_date
set height_is_valid = true
where height is not null;

update morocco_buildings_date
set height_is_valid = false,
    height = 6
where height is null;

select count(*)
from morocco_buildings_date;

select count(*)
from morocco_buildings;
