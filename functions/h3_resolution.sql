drop function if exists ZRes(z integer);

create or replace function ZRes(z integer)
    returns float
    returns null on null input
    language sql immutable as
$func$
select (40075016.6855785/(256*2^z));
$func$;


drop table if exists h3_resolutions;

create table h3_resolutions (id integer, edge_length float);

insert into h3_resolutions (id, edge_length) select i, h3_edge_length(i) from generate_series(0,15) i;


drop function if exists calculate_h3_res(z integer);

create or replace function calculate_h3_res(z integer)
    returns integer
    returns null on null input
    language sql immutable as
$func$
SELECT id FROM h3_resolutions ORDER BY abs(ZRES(z) * 15 - edge_length) LIMIT 1;
$func$;

