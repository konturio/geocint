-- dither areas to not be bigger than 100% of hexagon's area for every resolution
drop procedure if exists dither_area_to_not_bigger_than_100pc_of_hex_area;
create or replace procedure dither_area_to_not_bigger_than_100pc_of_hex_area(input_table text,
                                                                             table_h3 text,                                                                             
                                                                             columns text[],
                                                                             resolution integer default 8)
language plpgsql
as

$$
    declare
        -- input_table text := input_table;
        -- table_h3    text := table_h3;
        res         integer := resolution;
        cur_row     jsonb;
        carry       jsonb;
        carry_out   jsonb;
    begin

        while res >= 0
            loop
                select jsonb_object_agg(column_name, 0) from unnest(columns) "column_name" into carry;

                for cur_row in execute '(select to_jsonb(r) from '|| quote_ident(input_table) || ' r where resolution = ' || res::text || ' order by h3)'
                    loop
                        
                        -- recursive сalculation carry value for every type of area
                        select jsonb_object_agg(c.key, carry_value - carry_out_value),
                               jsonb_object_agg(c.key, carry_out_value)
                        from jsonb_each(carry) c,
                             jsonb_each(cur_row) r,
                             lateral (select c.value::float + r.value::float "carry_value") "carry_value",
                             least(carry_value::float, (cur_row -> 'area_km2')::float) "carry_out_value"
                        where c.key = r.key
                        into carry, carry_out;

                        -- insert new value when difference between forest and hexagon area area is bigger then zero 
                            if jsonb_path_exists(carry_out, '$.** ? (@ > 0)') then
                            execute 'insert into '|| quote_ident(table_h3) || '
                            select *
                            from jsonb_populate_record(null::' || quote_ident(table_h3) || ', cur_row || carry_out)';
                        end if;
                    end loop;

                raise notice 'unprocessed carry %', carry;
                res = res - 1;
            end loop;
    end;
$$;
