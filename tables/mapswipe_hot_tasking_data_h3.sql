drop table if exists mapswipe_hot_tasking_data_subdivide;
create table mapswipe_hot_tasking_data_subdivide as (
	select id, 
	       ST_Subdivide(geom, 5) geom
	from mapswipe_hot_tasking_data
);

create index on mapswipe_hot_tasking_data_subdivide using gist(geom);

drop table if exists land_polygons_h3_r8_4326;
create table land_polygons_h3_r8_4326 as (
	select h3,
	       ST_Transform(geom, 4326) as geom,
	       area
	from land_polygons_h3_r8
);

drop table if exists mapswipe_hot_tasking_data_h3_in;
create table mapswipe_hot_tasking_data_h3_in as (
	select l.h3               as h3, 
	       sum(ST_Area(s.geom::geography)) / 1000000.0 as mapswipe_area,
	       l.area / 1000000.0 as area_km2, 
	       8                  as resolution
	from mapswipe_hot_tasking_data_subdivide s, 
	     land_polygons_h3_r8_4326 l 
	where ST_Intersects(s.geom, l.geom) 
	group by 1, 3
);

-- Remove temporary table
drop table if exists mapswipe_hot_tasking_data_subdivide;
drop table if exists land_polygons_h3_r8_4326;

-- generate overviews and dithering from copernicus_forest_h3.sql

-- generate overviews
-- TODO: rewrite generated_overviews() procedure to receive expression to "method" parameter for column
do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into mapswipe_hot_tasking_data_h3_in (h3, mapswipe_area, area_km2, resolution)
                select h3_cell_to_parent(h3),
                       sum(mapswipe_area),
                       ST_Area(h3_cell_to_boundary_geography(h3_cell_to_parent(h3))) / 1000000.0,
                       (res - 1)
                from mapswipe_hot_tasking_data_h3_in
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;

drop table if exists mapswipe_hot_tasking_data_h3;
create table mapswipe_hot_tasking_data_h3
(
    like mapswipe_hot_tasking_data_h3_in
);

-- dither areas to not be bigger than 100% of hexagon's area for every resolution
do
$$
    declare
        columns   text[];
        res       integer;
        cur_row   jsonb;
        carry     jsonb;
        carry_out jsonb;
    begin
        columns = '{mapswipe_area}';
        res = 8;
        while res >= 0
            loop
                select jsonb_object_agg(column_name, 0) from unnest(columns) "column_name" into carry;
                for cur_row in (select to_jsonb(r) from mapswipe_hot_tasking_data_h3_in r where resolution = res order by h3)
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
                            insert into mapswipe_hot_tasking_data_h3
                            select *
                            from jsonb_populate_record(null::mapswipe_hot_tasking_data_h3, cur_row || carry_out);
                        end if;
                    end loop;
                raise notice 'unprocessed carry %', carry;
                res = res - 1;
            end loop;
    end;
$$;

drop table if exists mapswipe_hot_tasking_data_h3_in;