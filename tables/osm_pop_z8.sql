drop table if exists osm_pop_z8;
create table osm_pop_z8 (
    h3         h3index,
    geom       geometry,
    orig_pop   float,
    population float
)
    tablespace pg_default;


do
$$
    declare
        carry   float;
        cur_pop float;
        max_pop float;
        cur_row record;
    begin
        carry = 0;
        for cur_row in ( select *
                         from osm_object_count_grid_h3_with_population
                         where resolution = 8
                         order by h3 )
            loop
                cur_pop = cur_row.population + carry;
                max_pop = cur_row.max_population;
                if (max_pop <= 0)
                then
                    cur_pop = 0;
                end if;
                if cur_row.building_count > 0 and cur_pop < 1
                then
                    cur_pop = 1;
                    if (max_pop <= 0)
                    then
                        max_pop = 46200;
                    end if;
                end if;
                if (cur_row.building_count/2) > cur_pop
                then
                    cur_pop = cur_row.building_count / 2;
                end if;
                if cur_pop < 0
                then
                    cur_pop = 0;
                end if;
                -- Population density of Manila is 46178 people/km2 and that's highest on planet
                if (cur_pop / cur_row.area_km2) > max_pop
                then
                    cur_pop = max_pop * cur_row.area_km2;
                end if;

                cur_pop = floor(cur_pop);

                carry = cur_row.population + carry - cur_pop;
                if cur_pop > 0
                then
                    insert into osm_pop_z8 (h3, geom, orig_pop, population)
                    values (cur_row.h3, cur_row.geom, cur_row.population, cur_pop);
                end if;
                --         raise notice '% pop, % new pop, % carry, % buildings ', cur_row.population, cur_pop, carry, cur_row.building_count;
            end loop;
        raise notice 'unprocessed carry %', carry;
    end;
$$;

create index on osm_pop_z8 using gist(geom);

