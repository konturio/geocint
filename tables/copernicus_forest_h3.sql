drop table if exists copernicus_forest_h3_in;
create table copernicus_forest_h3_in as (
    select h3,
           8                                                               as resolution,
           evergreen_needle_leaved_forest / 1000000                        as evergreen_needle_leaved_forest,
           shrubs / 1000000                                                as shrubs,
           herbage / 1000000                                               as herbage,
           unknown_forest / 1000000                                        as unknown_forest,
           forest_area / 1000000                                           as forest_area,
           ST_Area(h3_to_geo_boundary_geometry(h3)::geography) / 1000000.0 as area_km2
    from (
             select p_h3                                                             as h3,
                    coalesce(sum(cell_area) filter (where p.val in (111, 121)), 0)   as evergreen_needle_leaved_forest,
                    coalesce(sum(cell_area) filter (where p.val = 20), 0)            as shrubs,
                    coalesce(sum(cell_area) filter (where p.val = 30), 0)            as herbage,
                    coalesce(sum(cell_area) filter (where p.val in (116, 126)), 0)   as unknown_forest,
                    coalesce(sum(cell_area) filter (where p.val not in (20, 30)), 0) as forest_area
             from copernicus_landcover_raster c,
                  ST_PixelAsPolygons(rast) p,
                  h3_geo_to_h3(p.geom::box::point, 8) as p_h3,
                  ST_Area(p.geom::geography) as cell_area
             where p.val in (20, 30, 111, 113, 112, 114, 115, 116, 121, 123, 122, 124, 125, 126)
             group by 1
         ) x
);

-- p.val list based on Discrete classification coding
-- from Copernicus Global Land Service: https://zenodo.org/record/4723921#.YQmESVMzaDV


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
                insert into copernicus_forest_h3_in (h3, forest_area, evergreen_needle_leaved_forest, shrubs, herbage,
                                                     unknown_forest, area_km2, resolution)
                select h3_to_parent(h3),
                       sum(forest_area),
                       sum(evergreen_needle_leaved_forest),
                       sum(shrubs),
                       sum(herbage),
                       sum(unknown_forest),
                       ST_Area(h3_to_geo_boundary_geometry(h3_to_parent(h3))::geography) / 1000000.0,
                       (res - 1)
                from copernicus_forest_h3_in
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;

drop table if exists copernicus_forest_h3;
create table copernicus_forest_h3
(
    like copernicus_forest_h3_in
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
        columns = '{forest_area, evergreen_needle_leaved_forest, shrubs, herbage, unknown_forest}';
        res = 8;
        while res > 0
            loop
                select jsonb_object_agg(column_name, 0) from unnest(columns) "column_name" into carry;
                for cur_row in (select to_jsonb(r) from copernicus_forest_h3_in r where resolution = res order by h3)
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
                            insert into copernicus_forest_h3
                            select *
                            from jsonb_populate_record(null::copernicus_forest_h3, cur_row || carry_out);
                        end if;
                    end loop;
                raise notice 'unprocessed carry %', carry;
                res = res - 1;
            end loop;
    end;
$$;

drop table if exists copernicus_forest_h3_in;
