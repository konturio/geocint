-- this function selects country polygon by hasc
-- selects hexagons inside this polygon
-- dithers ghs population (makes values integer and checks that density per hexagon is < 46200)
-- saves results to tab_result

CREATE OR REPLACE FUNCTION ghs_pop_dither(tab_source text, tab_result text)
RETURNS void AS
$BODY$
DECLARE
    carry   float;
    cur_pop float;
    cur_row record;
    max_pop float;
begin
    carry := 0;
    max_pop := 46200; -- Population density of Manila is 46178 people/km2 and that's highest on planet

    for cur_row in execute format('select h3, 
                                          population, 
                                          ST_Area(h3_cell_to_boundary_geography(h3)) / 1000000.0 as area_km2 
                                   from %s 
                                   order by h3', tab_source) loop
        cur_pop := cur_row.population + carry;

        if cur_pop < 0 then
            cur_pop := 0;
        end if;

        if (cur_pop / cur_row.area_km2) > max_pop then
            cur_pop := max_pop * cur_row.area_km2;
        end if;

        cur_pop := floor(cur_pop);
        carry := cur_row.population + carry - cur_pop;

        if cur_pop > 0 then
            execute format('insert into %s (h3, population, geom)
            values ($1, $2, $3)', tab_result)
            using cur_row.h3, cur_pop, h3_cell_to_boundary_geometry(cur_row.h3);
        end if;
    end loop;
END;
$BODY$ 
LANGUAGE plpgsql VOLATILE COST 100;