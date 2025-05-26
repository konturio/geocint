drop procedure if exists generate_overviews;
create or replace procedure generate_overviews(table_h3 text,
                                               item_count text[],
                                               method text[],
                                               start_resolution integer default 8)
language plpgsql
as
$$
declare
    res         integer := start_resolution;
    item_list   text;
    column_list text;
begin
    select string_agg(format('%1$s(%2$i)', func, col), ',')
    into item_list
    from unnest(method, item_count) t(func, col);

    select string_agg(format('%1$s', col), ',')
    into column_list
    from unnest(item_count) t(col);

    -- Temporarily disable WAL logging for performance
    execute 'alter table ' || quote_ident(table_h3) || ' set unlogged';

    -- Aggregate from higher to lower H3 resolutions
    while res > 0 loop
        execute format(
            'insert into %i (h3, %s, resolution) ' ||
            'select h3_cell_to_parent(h3), %s, %l ' ||
            'from %i where resolution = %l group by 1',
            table_h3, column_list, item_list, res - 1, table_h3, res
        );
        res := res - 1;
    end loop;

    -- Re-enable WAL logging
    execute 'alter table ' || quote_ident(table_h3) || ' set logged';
end;
$$;
