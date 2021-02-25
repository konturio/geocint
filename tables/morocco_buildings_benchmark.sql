alter table :morocco_buildings
    rename column wkb_geometry to geom;
alter table :morocco_buildings
    alter column geom type geometry;
alter table :morocco_buildings
    drop column id;
alter table :morocco_buildings
    drop column _block_id;
alter table :morocco_buildings
    drop column shape_type;
alter table :morocco_buildings
    drop column osm_landuse_class;
alter table :morocco_buildings
    rename column processing_date to imagery_vintage;
alter table :morocco_buildings
    rename column _height_confidence to height_confidence;

-- convert multipolygons to polygons
update :morocco_buildings
set geom = ST_CollectionHomogenize(geom);

-- make geom robust to conversion to mercator
update :morocco_buildings
set geom = ST_CollectionExtract(ST_MakeValid(ST_Transform(geom, 3857)), 3) where ST_SRID(geom) != 3857 or not ST_IsValid(geom);
