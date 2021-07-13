drop function if exists generate_overviews(table_h3 text, item_count text, start_resolution integer);

create or replace function generate_overviews(table_h3 text,
                                              item_count text,
                                              method text default 'sum',
                                              start_resolution integer default 8)
    returns integer
    language plpgsql
    volatile
as
$$
declare
    res integer := start_resolution;
begin
    while res > 0
        loop
            execute '
                insert into ' || table_h3 || ' (h3, ' || item_count || ', resolution)
                select h3_to_parent(h3) as h3, ' || method || '(' || item_count || '), ' || (res - 1)::text || ' as resolution
                from ' || table_h3 || '
                where resolution = ' || res::text || '
                group by 1';
            res = res - 1;
        end loop;

    return 0;
end;
$$;
