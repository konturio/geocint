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

do
$$
    declare
        i integer;
    begin
        for i in 0..15
            loop
                insert into h3_resolutions (id, edge_length) values (i, h3_edge_length(i));
            end loop;
    end;
$$;


drop function if exists calculate_h3_res(z integer);

create or replace function calculate_h3_res(z integer)
    returns integer
    returns null on null input
    language sql immutable as
$func$
SELECT id FROM
    (
        (SELECT id, edge_length FROM h3_resolutions WHERE edge_length >= ZRES(z) * 15  ORDER BY edge_length LIMIT 1)
        UNION ALL
        (SELECT id, edge_length FROM h3_resolutions WHERE edge_length < ZRES(z) * 15  ORDER BY edge_length DESC LIMIT 1)
    ) as foo
ORDER BY abs(ZRES(z) * 15 - edge_length) LIMIT 1;
$func$;

