-- Match high level kontur_boundaries with HASC codes by wikidata identifier
drop table if exists hdx_boundaries;

create table hdx_boundaries as (
    select
        hdx.hasc as hasc,
        ST_Subdivide(kbnd.geom) as geom
    from
        kontur_boundaries as kbnd
    inner join hdx_locations_with_wikicodes as hdx
        on hdx.wikicode = kbnd.tags ->> 'wikidata'
);

create index on hdx_boundaries using gist(geom);