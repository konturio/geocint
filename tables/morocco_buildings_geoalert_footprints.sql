-- change schema to match the one expected by consumers
alter table morocco_buildings_geoalert_footprints
    alter column geom type geometry;
alter table morocco_buildings_geoalert_footprints
    drop column id;
alter table morocco_buildings_geoalert_footprints
    drop column _block_id;
alter table morocco_buildings_geoalert_footprints
    drop column processing_date;
alter table morocco_buildings_geoalert_footprints
    drop column shape_type;
alter table morocco_buildings_geoalert_footprints
    drop column osm_landuse_class;
alter table morocco_buildings_geoalert_footprints
    rename column _height_confidence to height_is_valid;

-- convert multipolygons to polygons
update morocco_buildings
set geom = ST_CollectionHomogenize(geom);

-- drop geometry with type MultiSurface
delete
from morocco_buildings
where ST_GeometryType(geom) = 'ST_MultiSurface';

-- make geom robust to conversion to mercator
update morocco_buildings
set geom = ST_CollectionExtract(ST_MakeValid(geom), 3)
where not ST_IsValid(ST_Transform(geom, 3857));

select count(geom), ST_GeometryType(geom)
from morocco_buildings
group by 2;