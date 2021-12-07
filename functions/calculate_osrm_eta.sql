create or replace function calculate_osrm_eta(
    sources geometry[], -- source geometries
    destinations geometry[], -- destination geometries
    profile text, -- OSRM profile
    max_table_size integer = 1000 -- max-table-size setting in OSRM
)
    returns table
            (
                eta    float,
                start  geometry,
                finish geometry
            )
    cost 10000
    language plpgsql
as
$$
declare
    source_parts float;
begin
    -- find the size to split the array of sources
    source_parts = array_length(sources, 1)::float / (
            array_length(sources, 1) +
            array_length(destinations, 1)
        ) * max_table_size;
    if array_length(sources, 1) < array_length(destinations, 1) then
        source_parts = ceil(source_parts);
    else
        source_parts = floor(source_parts);
    end if;
    return query
        -- split sources by chunks
        with src_chunks as (
            select array_agg(ST_X(point) || ',' || ST_Y(point)) "coords",
                   count(*)                                     "length"
            from unnest(sources) with ordinality s(geom, idx),
                 ST_Transform(ST_PointOnSurface(geom), 4326) "point"
            group by floor((s.idx - 1) / source_parts)
        ),
             -- split destinations by chunks
             dst_chunks as (
                 select array_agg(ST_X(point) || ',' || ST_Y(point)) "coords",
                        count(*)                                     "length"
                 from unnest(destinations) with ordinality d(geom, idx),
                      ST_Transform(ST_PointOnSurface(geom), 4326) "point"
                 group by floor((d.idx - 1) / (max_table_size - source_parts))
             ),
             -- generates links to query the OSRM
             urls as (
                 select 'http://localhost:' ||
                        case profile
                            when 'foot' then 5000
                            when 'bicycle' then 5001
                            when 'car' then 5002
                            when 'emergency' then 5003
                            end ||
                        '/table/v1/' || profile || '/' ||
                        array_to_string(s.coords, ';') || ';' || array_to_string(d.coords, ';') ||
                        '?sources=' || (select string_agg(i::text, ';') from generate_series(0, s.length - 1) i) ||
                        '&destinations=' || (select string_agg(i::text, ';')
                                             from generate_series(s.length, s.length + d.length - 1) i) "url",
                        s.coords                                                                        "src_coords",
                        d.coords                                                                        "dst_coords"
                 from src_chunks s,
                      dst_chunks d
             )
        select (j -> 'durations' -> source_id ->> destination_id)::float                                  "eta",
               -- recreate geometries from sources and destinations
               -- don't use location from json because of coordinate precision
               ST_GeomFromEWKT('SRID=4326;POINT(' || replace(src_coords[source_id + 1], ',', ' ') || ')') "src_point",
               ST_GeomFromEWKT('SRID=4326;POINT(' || replace(dst_coords[destination_id + 1], ',', ' ') ||
                               ')')                                                                       "dst_point"
        from urls,
             http_get(url) h,
             cast(h.content as jsonb) j,
             generate_series(0, jsonb_array_length(j -> 'durations') - 1) source_id,
             generate_series(0, jsonb_array_length(j -> 'durations' -> source_id) - 1) destination_id;
end;
$$;