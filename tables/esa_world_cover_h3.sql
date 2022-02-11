drop table if exists esa_world_cover_h3_in;
create table esa_world_cover_h3_in as (
    select p_h3                                                               as h3,
           8                                                                  as resolution,
           coalesce(sum(cell_area) filter (where p.val = 10), 0) /1000000     as tree_cover,
           coalesce(sum(cell_area) filter (where p.val = 20), 0) /1000000     as shrubland,
           coalesce(sum(cell_area) filter (where p.val = 30), 0) /1000000     as grassland,
           coalesce(sum(cell_area) filter (where p.val = 40), 0) /1000000     as cropland,
           coalesce(sum(cell_area) filter (where p.val = 50), 0) /1000000     as built_up,
           coalesce(sum(cell_area) filter (where p.val = 60), 0) /1000000     as bare_sparse_vegetation,
           coalesce(sum(cell_area) filter (where p.val = 70), 0) /1000000     as show_and_ice,
           coalesce(sum(cell_area) filter (where p.val = 80), 0) /1000000     as permanent_water_bodies,
           coalesce(sum(cell_area) filter (where p.val = 90), 0) /1000000     as herbaceous,
           coalesce(sum(cell_area) filter (where p.val = 95), 0) /1000000     as mangroves,
           coalesce(sum(cell_area) filter (where p.val = 100), 0) /1000000    as moss_and_lichen,
           ST_Area(h3_to_geo_boundary_geometry(p_h3)::geography) / 1000000.0  as area_km2
    from esa_world_cover c,
          ST_PixelAsPolygons(rast) p,
          h3_geo_to_h3(p.geom::box::point, 8) as p_h3,
          ST_Area(p.geom::geography) as cell_area
    where p.val in (10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 100)
    group by 1
         
);

-- p.val list based on ESA world Cover Product User Manual
-- from: https://worldcover2020.esa.int/data/docs/WorldCover_PUM_V1.1.pdf


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
                insert into esa_world_cover_h3_in (h3, tree_cover, shrubland, grassland, cropland, built_up, bare_sparse_vegetation, 
                                                       show_and_ice, permanent_water_bodies, herbaceous, mangroves, moss_and_lichen, area_km2, resolution)
                select h3_to_parent(h3),
                       sum(tree_cover),
                       sum(shrubland),
                       sum(grassland),
                       sum(cropland),
                       sum(built_up),
                       sum(bare_sparse_vegetation),
                       sum(show_and_ice),
                       sum(permanent_water_bodies),
                       sum(herbaceous),
                       sum(mangroves),
                       sum(moss_and_lichen),
                       ST_Area(h3_to_geo_boundary_geometry(h3_to_parent(h3))::geography) / 1000000.0,
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
        columns = '{tree_cover, shrubland, grassland, cropland, built_up, bare_sparse_vegetation, show_and_ice, permanent_water_bodies, herbaceous, mangroves, moss_and_lichen}';
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
