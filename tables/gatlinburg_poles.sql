drop table if exists osm_poles_towers;
create table osm_poles_towers as (
    select osm_id, 
           osm_type, 
           tags, 
           ST_Normalize(geog::geometry) as geom 
    from osm 
    where tags @> '{"power":"pole"}' 
       or tags @> '{"power":"tower"}'
);

create index on osm_poles_towers using gist(geom);

drop table if exists testcity_poles;
create table testcity_poles as (
    select p.osm_id as objectid,
           'osm'    as source,
           geom
    from osm_poles_towers p, testcity g 
    where ST_Intersects(p.geom, g.geom)
    union all
    select objectid,
           source,
           geom
    from county_poles_without_osm
);
create index on testcity_poles using gist(geom);

drop table if exists osm_poles_towers;