set timezone to 'UTC';

drop table if exists gfw_vessel_flags;
create table gfw_vessel_flags as (
    select json->>'id' as id,
           coalesce(json->>'flag','UNK') as flag
    from gfw_vessel_flags_raw
);
create unique index on gfw_vessel_flags(id);
