drop table if exists wsf_population_h3;
create table wsf_population_h3 as (
    select h3,
           11 as resolution,
           population
    from (
             select p_h3                  as h3,
                    coalesce(sum(p.val), 0) as population
             from wsf_population_raster c,
                  ST_PixelAsPolygons(rast) p,
                  h3_lat_lng_to_cell(p.geom::box::point, 11) as p_h3
             where p.val > 0
             group by 1
         ) x
);

call generate_overviews('wsf_population_h3', '{population}'::text[], '{sum}'::text[], 11);
