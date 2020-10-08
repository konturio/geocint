drop table if exists morocco_buildings_valid;
create table morocco_buildings_valid as (
    select building_height,
           ST_Transform(ST_CollectionExtract(ST_MakeValid(geom), 3), 3857) as geom
       from morocco_buildings);
