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
alter table morocco_buildings
    rename column height to building_height;

-- convert multipolygons to polygons
update morocco_buildings
set geom = ST_CollectionHomogenize(geom);

-- make geom robust to conversion to mercator
update morocco_buildings
set geom = ST_CollectionExtract(ST_MakeValid(ST_Transform(ST_MakeValid(ST_Transform(geom, 3857)), 4326)), 3)
where not ST_IsValid(ST_Transform(geom, 3857));
