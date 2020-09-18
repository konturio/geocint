alter table morocco_buildings
    alter column geom type geometry;
alter table morocco_buildings
    drop column fid;
alter table morocco_buildings
    drop column _block_id;
alter table morocco_buildings
    drop column processing_date;
alter table morocco_buildings
    drop column shape_type;
alter table morocco_buildings
    drop column osm_landuse_class;
alter table morocco_buildings
    rename column is_validated to manually_reviewed;
alter table morocco_buildings
    rename column is_footprint to height_is_valid;
update morocco_buildings
set geom = ST_CollectionHomogenize(geom);
