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

insert into h3_resolutions (id, edge_length) values (0, 1107.712591000);
insert into h3_resolutions (id, edge_length) values (1, 418.6760055);
insert into h3_resolutions (id, edge_length) values (2, 158.244655800);
insert into h3_resolutions (id, edge_length) values (3, 59.810857940);
insert into h3_resolutions (id, edge_length) values (4, 59.810857940);
insert into h3_resolutions (id, edge_length) values (5, 8.544408276);
insert into h3_resolutions (id, edge_length) values (6, 3.229482772);
insert into h3_resolutions (id, edge_length) values (7, 1.220629759);
insert into h3_resolutions (id, edge_length) values (8, 0.461354684);
insert into h3_resolutions (id, edge_length) values (9, 0.174375668);
insert into h3_resolutions (id, edge_length) values (10, 0.065907807);
insert into h3_resolutions (id, edge_length) values (11, 0.024910561);
insert into h3_resolutions (id, edge_length) values (12, 0.009415526);
insert into h3_resolutions (id, edge_length) values (13, 0.003559893);
insert into h3_resolutions (id, edge_length) values (14, 0.001348575);
insert into h3_resolutions (id, edge_length) values (15, 0.000509713);


drop function if exists calculate_h3_res(z integer);

create or replace function calculate_h3_res(z integer)
    returns integer
    returns null on null input
    language sql immutable as
$func$
SELECT id FROM
    (
        (SELECT id, edge_length FROM h3_resolutions WHERE edge_length >= ZRES(z) * 15 / 1000 ORDER BY edge_length LIMIT 1)
        UNION ALL
        (SELECT id, edge_length FROM h3_resolutions WHERE edge_length < ZRES(z) * 15 / 1000 ORDER BY edge_length DESC LIMIT 1)
    ) as foo
ORDER BY abs(ZRES(z) * 15 / 1000 - edge_length) LIMIT 1;
$func$;

