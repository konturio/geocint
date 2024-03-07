do
$$
    declare
        carry     float;
        cur_value float;
        cur_row   record;
    begin
        -- drop final table if exists before creation
        drop table if exists unemployment_rates_h3;

        -- create final table
        create table unemployment_rates_h3 (h3 h3index, unemployment_rate integer, resolution integer);

        carry = 0;
        for cur_row in (select * from unemployment_rates_h3_mid order by h3)
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
                    insert into unemployment_rates_h3 (h3, unemployment_rate, resolution)
                    values (cur_row.h3, cur_value, 8);
                end if;
            end loop;
        raise notice 'unprocessed carry %', carry;
    end;
$$;