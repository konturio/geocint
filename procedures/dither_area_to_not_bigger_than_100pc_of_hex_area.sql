do
$$
    declare
        -- columns   text[];
        res       integer;
        cur_row   jsonb;
        carry     jsonb;
        carry_out jsonb;
    begin
        -- res = :start_resolution::integer;

        res = 8::integer

        while res >= 0
            loop
                select jsonb_object_agg(column_name, 0) from unnest('columns_list'::text[]) "column_name" into carry;
                for cur_row in (select to_jsonb(r) from :input_table r where resolution = res order by h3)
                    loop
                        -- recursive сalculation carry value for every forest type area
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
                            insert into :table_h3
                            select *
                            from jsonb_populate_record(null:::table_h3, cur_row || carry_out);
                        end if;
                    end loop;
                raise notice 'unprocessed carry %', carry;
                res = res - 1;
            end loop;
    end;
$$;