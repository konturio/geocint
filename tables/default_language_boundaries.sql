-- select relations with default language and admin level
drop table if exists default_language_relations_with_admin_level;
create table default_language_relations_with_admin_level as (    
    select osm_id,
           -- process non-integer admin levels
           round((tags ->> 'admin_level')::float)  as admin_level,
           tags ->> 'default_language'             as default_language,
           ST_Normalize(geog::geometry)            as geom
    from osm
    where tags ? 'default_language'  
          and tags ->> 'admin_level' ~E'^\\d+$' 
          and not (tags @> '{"disputed":"yes"}' or tags @> '{"boundary":"disputed"}')
          and osm_type = 'relation'  
);

-- select relations with default language but without admin_level
drop table if exists default_language_relations_without_admin_level;
create table default_language_relations_without_admin_level as (    
    select osm_id                       as osm_id,
           null::integer                as admin_level,
           tags ->> 'default_language'  as default_language,
           tags                         as tags,
           ST_Normalize(geog::geometry) as geom
    from osm
    where tags ? 'default_language'  
          and not tags ? 'admin_level' 
          and not (tags @> '{"disputed":"yes"}' or tags @> '{"boundary":"disputed"}')
          and osm_type = 'relation'      
);

-- delete claimed relations
with claimed_relations as(
        select distinct osm_id 
        from (select jsonb_object_keys(tags) as tag, 
                     osm_id 
              from default_language_relations_without_admin_level) q 
        where tag ilike '%claimed%'
        )
delete from default_language_relations_without_admin_level  
    where osm_id in (select osm_id from claimed_relations);

-- set lowest admin level for relation without it
update default_language_relations_without_admin_level
    set admin_level = (select max(admin_level)+1 from default_language_relations_with_admin_level);

-- union relation where admin_level less than 2
drop table if exists default_language_relations;
create table default_language_relations as (
    select osm_id,
           admin_level,
           default_language,
           geom,
           ST_Area(geom) as area
    from default_language_relations_with_admin_level
    where admin_level > 2
    union all 
    select osm_id,
           admin_level,
           default_language,
           geom,
           ST_Area(geom) as area
    from default_language_relations_without_admin_level
);

create index on default_language_relations using gist(geom);

-- union relation where admin_level = 2
drop table if exists default_language_relations_adm_2;
create table default_language_relations_adm_2 as (
    select * 
    from default_language_relations_with_admin_level 
    where admin_level = 2
);

-- update default languages for countries from static csv table to avoid errors during extrapolation
update default_language_relations_adm_2 p
    set default_language = k.lang
    from default_languages_2_level k
    where p.osm_id = k.osm_id;

create index on default_language_relations_adm_2 using gist(geom);

drop table if exists boundaries_with_default_language;
create table boundaries_with_default_language as (
    select osm_id,
           admin_level,
           default_language,
           geom
    from default_language_relations_with_admin_level
    where osm_id not in (select osm_id from default_languages_2_level)
    union all 
    select osm_id,
           admin_level,
           default_language,
           geom
    from default_language_relations_without_admin_level
    where osm_id not in (select osm_id from default_languages_2_level)
    union all
    select osm_id,
           2 as admin_level,
           lang as default_language,
           geom
    from default_languages_2_level
);

