alter table morocco_buildings_benchmark
    rename column wkb_geometry to geom;
alter table morocco_buildings_benchmark
    alter column geom type geometry;
alter table morocco_buildings_benchmark
    drop column id;
alter table morocco_buildings_benchmark
    drop column _block_id;
alter table morocco_buildings_benchmark
    drop column shape_type;
alter table morocco_buildings_benchmark
    drop column class_id;
alter table morocco_buildings_benchmark
    drop column osm_landuse_class;
alter table morocco_buildings_benchmark
    rename column processing_date to imagery_vintage;
alter table morocco_buildings_benchmark
    rename column _height_confidence to height_confidence;

-- convert multipolygons to polygons
update morocco_buildings_benchmark
set geom = ST_CollectionHomogenize(geom);

-- drop geometry with type MultiSurface
delete
from morocco_buildings_benchmark
where ST_GeometryType(geom) = 'ST_MultiSurface';

-- make geom robust to conversion to mercator
update morocco_buildings_benchmark
set geom = ST_CollectionExtract(ST_MakeValid(geom), 3)
where not ST_IsValid(ST_Transform(geom, 3857));

alter table morocco_buildings_benchmark
    alter column geom type geometry;
update morocco_buildings_benchmark
set geom = ST_Transform(ST_SetSRID(geom, 4326), 3857);
