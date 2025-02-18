drop table if exists osm_poles_towers;
create table osm_poles_towers as (
    select osm_id, 
           osm_type, 
           tags, 
           st_normalize(geog::geometry) as geom 
    from osm 
    where tags @> '{"power":"pole"}' 
       or tags @> '{"power":"tower"}'
);

create index on osm_poles_towers using gist(geom);

drop table if exists gatlinburg_poles;
create table gatlinburg_poles as (
    select p.osm_id as objectid,
           'osm'    as source,
           geom
    from osm_poles_towers p, gatlinburg g 
    where st_intersects(p.geom, g.geom)
    union all
    select objectid,
           source,
           geom
    from sevier_county_poles_without_osm
);
create index on gatlinburg_poles using gist(geom);

drop table if exists osm_poles_towers;