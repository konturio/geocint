create or replace function date_or_null(input_value text)
   returns date
   immutable
   parallel unsafe
   cost 1
as
$$
begin
    return $1::date;
exception
    when others then
        return null;
end;
$$
language plpgsql;

drop table if exists wikidata_population;

create table wikidata_population as (
    select distinct on (wikidata_name, wikidata_item)
        wikidata_item,
        wikidata_name,
        population,
        date_or_null(census_date) as census_date
    from
        wikidata_population_in
    order by
        wikidata_name asc,
        wikidata_item asc,
        4 desc nulls last,
        population desc
);