drop table if exists esa_world_cover_h3_in;
create table esa_world_cover_h3_in as (
    select
        h3,
        8 as resolution,
        class_1 / class_all * area as tree_cover,
        class_2 / class_all * area as shrubland,
        class_4 / class_all * area as cropland,
        area as area_km2
    from esa_world_cover_h3_r8
);

-- p.val list based on ESA world Cover Product User Manual
-- from: https://worldcover2020.esa.int/data/docs/WorldCover_PUM_V1.1.pdf
-- Area calculation based on https://github.com/wgnet/globalmap/blob/master/code/postgis_wrappers/ST_Fast_Real_Area.sql


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
                insert into esa_world_cover_h3_in (h3, tree_cover, shrubland, cropland, area_km2, resolution)
                select h3_to_parent(h3),
                       sum(tree_cover),
                       sum(shrubland),
                       sum(cropland),
                       sum(area_km2),
                       (res - 1)
                from esa_world_cover_h3_in
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;

drop table if exists esa_world_cover_h3;
create table esa_world_cover_h3
(
    like esa_world_cover_h3_in
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
        columns = '{tree_cover, shrubland, cropland}';
        res = 8;
        while res > 0
            loop
                select jsonb_object_agg(column_name, 0) from unnest(columns) "column_name" into carry;
                for cur_row in (select to_jsonb(r) from esa_world_cover_h3_in r where resolution = res order by h3)
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
                            insert into esa_world_cover_h3
                            select *
                            from jsonb_populate_record(null::esa_world_cover_h3, cur_row || carry_out);
                        end if;
                    end loop;
                raise notice 'unprocessed carry %', carry;
                res = res - 1;
            end loop;
    end;
$$;

drop table if exists esa_world_cover_h3_in;
