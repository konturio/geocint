-- Match high level kontur_boundaries with HASC codes by wikidata identifier
drop table if exists hdx_boundaries;

create table hdx_boundaries as (
    select distinct on (hdx.hasc)
        hdx.hasc                          as hasc,
        kbnd.hasc_wiki                    as hasc_wiki,
        coalesce(kbnd.name_en, kbnd.name) as name,
        ST_Subdivide(kbnd.geom)           as geom
    from
        kontur_boundaries as kbnd
    inner join hdx_locations_with_wikicodes as hdx
        on hdx.wikicode = kbnd.tags ->> 'wikidata'
    order by hdx.hasc, ST_Area(geom) desc
);

create index on hdx_boundaries using gist(geom);