-- 'osm_id = 304716' for India
-- takes ~15 min to create table
-- 'rast &&' to force use index

-- :tab_temp is required to run dithering
drop table if exists :tab_temp;

create table :tab_temp (h3 h3index, population float);

-- clip world raster by India polygon
with cnt_clip as (select rid, rast
    from :tab_name as r,
        kontur_boundaries as b
    where rast && st_transform(geom, 54009) and
        st_intersects(rast, st_transform(geom, 54009))
        and b.osm_id = 304716)
, h3_r8 as (select (hs).h3, ((hs).stats).sum as population
    from cnt_clip, 
        lateral h3_raster_summary_centroids(rast, 8) as hs)
insert into :tab_temp(h3, population)
select h3, population
from h3_r8;

-- there are hexagons outside india polygon
-- delete hexagons outside
with bad as (select h3
    from :tab_temp
    except
    select h3
    from :tab_temp as a,
        kontur_boundaries as b
    where st_within(h3_cell_to_geometry(h3), b.geom)
        and b.osm_id = 304716)
delete from :tab_temp
where h3 in (select h3 from bad);

-- there are duplicates in h3 (TODO investigeate why they are exist)
-- delete duplicates and insert sum of their values
with bad as (select h3, sum(population) as new_pop
    from :tab_temp
    group by h3
    having count(*) > 1)
, d as (delete from :tab_temp
    where h3 in (select h3 from bad))
insert into :tab_temp(h3, population)
select h3, new_pop
from bad;

-- tab_result is required to insert values after dithering
drop table if exists :tab_result;

create table :tab_result(h3 h3index, population int, geom geometry(polygon, 4326));

-- using this procedure to lower the rounding to int error
-- how it works:
-- after rounding to int we take the decimal part from one hex
-- and propagate it to other hexes

-- this is workaround to use function, 
-- because substitution :tab_temp, :tab_result does not work within do-end block in sql file
-- this function is temporary so I delete it every run and did not move it to separate sql file
CREATE OR REPLACE FUNCTION dither_h3_by_column(tab_source text, tab_result text)
RETURNS void AS
$BODY$
DECLARE
    carry   float;
    cur_pop float;
    cur_row record;
    max_pop float;
begin
    carry := 0;
    max_pop := 46200;

    for cur_row in execute format('select h3, population, ST_Area(h3_cell_to_boundary_geography(h3)) / 1000000.0 as area_km2 from %s order by h3', tab_source) loop
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

-- run dithering
select dither_h3_by_column(:'tab_temp', :'tab_result');

drop FUNCTION if exists dither_h3_by_column(text, text);

drop table if exists :tab_temp;