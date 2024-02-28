-- dither derivatives of population to make sure that final result not fractional and equal or smaller than population
drop procedure if exists dither_area_to_not_bigger_than_100pc_of_hex_area;
create or replace procedure dither_population_derivatives(input_table text,
                                                          output_table text,
                                                          value_column text default 'value',                                                                          
                                                          population_column text default 'population',
                                                          resolution integer default 8)
language plpgsql
as

$$
    declare
        carry     float;
        cur_value float;
        cur_row   record;
        res       integer := resolution;
    begin
        -- drop final table if exists before creation
        execute 'drop table if exists ' || output_table;

        -- create final table
        execute 'create table ' || output_table || '(h3 h3index, ' || value_column || ' integer, resolution integer)';

        carry = 0;
        for cur_row in (select * from input_table order by h3)
            loop
                
                cur_value = cur_row.value + carry;
                
                if cur_value > cur_row.population
                then
                    cur_value = cur_row.population;
                end if;

                if cur_value < 0
                then
                    cur_value = 0;
                end if;
                
                cur_value = floor(cur_value);

                carry = cur_row.value + carry - cur_value;
                if cur_value >= 0
                then
                    execute 'insert into ' || output_table || ' (h3, ' || value_column || ', resolution)
                    values (cur_row.h3, cur_value, ' || res || ')';
                end if;
            end loop;
        raise notice 'unprocessed carry %', carry;
    end;
$$;