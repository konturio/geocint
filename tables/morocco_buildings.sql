alter table morocco_buildings
    alter column geom type geometry;
alter table morocco_buildings
    drop column _block_id;
alter table morocco_buildings
    drop column processing_date;
alter table morocco_buildings
    drop column shape_type;
alter table morocco_buildings
    drop column osm_landuse_class;
update morocco_buildings
set geom = ST_CollectionHomogenize(geom);

drop table if exists morocco_buildings_valid;
create table morocco_buildings_valid as (
    select building_height,
           ST_CollectionExtract(ST_MakeValid(geom), 3) as geom
    from morocco_buildings
);