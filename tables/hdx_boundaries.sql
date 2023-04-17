-- Match high level kontur_boundaries with HASC codes by wikidata identifier
drop table if exists hdx_boundaries;
create table hdx_boundaries as (
    with input as (
        select distinct on (hdx.hasc)
                hdx.hasc                          as hasc,
                kbnd.hasc_wiki                    as hasc_wiki,
                coalesce(kbnd.name_en, kbnd.name) as name,
                kbnd.geom                         as geom
        from kontur_boundaries as kbnd
        inner join hdx_locations_with_wikicodes as hdx
        on hdx.wikicode = kbnd.tags ->> 'wikidata'
        order by hdx.hasc, ST_Area(geom) desc)
    select hasc                   as hasc,
           hasc_wiki              as hasc_wiki,
           name                   as name,
           ST_Subdivide(geom)     as geom
    from input
);

create index on hdx_boundaries using gist(geom);