drop procedure if exists generate_overviews(table_h3 text, item_count text, method text, start_resolution integer);

create or replace procedure generate_overviews(table_h3 text,
                                              item_count text,
                                              method text default 'sum',
                                              start_resolution integer default 8)
    language plpgsql
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

end;
$$;
