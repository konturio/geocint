alter table morocco_buildings_benchmark_roofprints
    rename column wkb_geometry to geom;
alter table morocco_buildings_benchmark
    alter column geom type geometry;
alter table morocco_buildings_benchmark_roofprints
    drop column id;
alter table morocco_buildings_benchmark_roofprints
    drop column _block_id;
alter table morocco_buildings_benchmark_roofprints
    drop column shape_type;
alter table morocco_buildings_benchmark_roofprints
    drop column class_id;
alter table morocco_buildings_benchmark_roofprints
    drop column osm_landuse_class;
alter table morocco_buildings_benchmark_roofprints
    rename column processing_date to imagery_vintage;
alter table morocco_buildings_benchmark_roofprints
    rename column _height_confidence to height_confidence;

-- convert multipolygons to polygons
update morocco_buildings_benchmark_roofprints
set geom = ST_CollectionHomogenize(geom);

-- drop geometry with type MultiSurface
delete
from morocco_buildings_benchmark_roofprints
where ST_GeometryType(geom) = 'ST_MultiSurface';

-- make geom robust to conversion to mercator
update morocco_buildings_benchmark_roofprints
set geom = ST_CollectionExtract(ST_MakeValid(geom), 3)
where not ST_IsValid(ST_Transform(geom, 3857));