drop table if exists hdx_locations_with_wikicodes;

create table hdx_locations_with_wikicodes as (
    select distinct on (hasc)
        hdx.*,
        replace(wdh.wikidata_item, 'http://www.wikidata.org/entity/', '') as wikicode
    from
        hdx_locations as hdx
    left join wikidata_hasc_codes as wdh using(hasc)
);