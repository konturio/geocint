create or replace function osrm_table(
    source geometry, -- source point
    destinations geometry[], -- destination points
    profile text, -- OSRM profile
    max_table_size integer = 100 -- max-table-size setting in OSRM
)
    returns setof float
    parallel safe
    cost 10000
    language sql
as
$$
-- OSRM tables service is limited to 100 locations by default
select jsonb_array_elements_text(
                   (http_get('http://localhost:' ||
                             case profile
                                 when 'foot' then 5000
                                 when 'bicycle' then 5001
                                 when 'car' then 5002
                                 when 'emergency' then 5003
                                 end ||
                             '/table/v1/' || profile || '/' ||
                             ST_X(source) || ',' || ST_Y(source) || ';' ||
                             string_agg(ST_X(geom) || ',' || ST_Y(geom), ';') || '?sources=0'
                        )::jsonb -> 'durations' -> 0) - 0 -- remove source eta
           )::float eta
from (
         -- split destinations by max_table_size
         select (row_number() over () - 1) / max_table_size "part_id",
                geom
         from unnest(destinations) geom
     ) "table"
group by part_id
$$;
