with groups as (
    select (row_number() over () - 1) / 999 part_id, -- table partitioning
           src.id,
           src.building_height              height,
           dst.population,
           src_geom,
           dst.geom                         dst_geom,
           src.geom
    from abu_dhabi_buildings src,
         ST_PointOnSurface(src.geom) src_geom,
         ST_Buffer(src_geom::geography, 15 / 3.6 * 600) buffer,
         abu_dhabi_buildings_population dst
    where src.id = :id
      and ST_Intersects(buffer::geometry, dst.geom)
      and src.id != dst.id
)
insert into abu_dhabi_pds_bicycle_10min(id, height, pds, geom)
select g.id, height, sum(pds), geom
from (
         select id,
                height,
                geom,
                array_agg(population) population,
                -- request to OSRM table service
                (http_get('http://localhost:5001/table/v1/bicycle/' ||
                    ST_X(src_geom) || ',' || ST_Y(src_geom) || ';' ||
                    string_agg(ST_X(dst_geom) || ',' || ST_Y(dst_geom), ';') ||
                    '?sources=0&destinations=' ||
                    (
                        select string_agg(id::text, ';')
                        from generate_series(1, count(population)) id
                    )
                    )).content
         from groups
         group by part_id, id, height, geom, src_geom
     ) g
     cross join lateral (
    select unnest(population)                                            pds,
           jsonb_array_elements_text(content::jsonb -> 'durations' -> 0) eta
    ) e
where eta::float < 600
group by g.id, g.height, g.geom;
