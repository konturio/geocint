drop table if exists wb_gdp;
create table wb_gdp as (
    select (xpath('//field[@name="Country or Area"]/@key', x))[1]::text   as code,
           h.hasc                                                         as hasc,
           (xpath('//field[@name="Country or Area"]/text()', x))[1]::text as country,
           (xpath('//field[@name="Year"]/text()', x))[1]::text::int       as year,
           (xpath('//field[@name="Value"]/text()', x))[1]::text::float    as gdp
    from unnest(xpath('//record', (select * from temp_xml)::xml)) x
         left join hdx_locations_with_wikicodes h 
             on (xpath('//field[@name="Country or Area"]/@key', x))[1]::text = upper(h.code)
    where (xpath('//field[@name="Value"]/text()', x))[1]::text::float is not null
);
