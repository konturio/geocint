-- The procedure linear_segments_length_to_h3 calculates the length of linear objects per hexagon.
-- The procedure supports two modes: 
-- 1. 'dump' - A simple dump into segments, suitable for low resolutions. It is faster but may cause 
--    gaps in coverage if segment lengths exceed the hexagon size. 
-- 2. 'split_and_dump' - Segmentizes lines into a specific segment size before dumping. Suitable for 
--    high resolutions, slower but creates a more complete and accurate map.
-- Examples: 
-- call linear_segments_length_to_h3('roads', 'roads_h3_r8', 'dump', 'road_length', 8);
-- call linear_segments_length_to_h3('roads', 'roads_h3_r82', 'split_and_dump', 'road_length', 8, 0.5);

drop procedure if exists linear_segments_length_to_h3;
create or replace procedure linear_segments_length_to_h3(
    input_table text,
    output_h3_table text,
    mode text,
    output_length_field_name text,
    resolution integer default 8,
    split_distance double precision default 25
)
language plpgsql
as $$
declare
    res integer := resolution;
    source_data text;
    sql text;
begin
    
    if mode = 'dump' then
        source_data := 'st_dumpsegments(r.geom) s';
    elsif mode = 'split_and_dump' then
        source_data := 'st_dumpsegments(st_segmentize(r.geom::geography, ' || split_distance || ')::geometry) s';
    else
        raise exception 'Wrong mode value. Available options: dump, split_and_dump';
    end if;

    execute format('drop table if exists %I ', output_h3_table);

    sql := format('
        create table %I as 
        select 
            h3_lat_lng_to_cell(st_startpoint(s.geom)::point, %s) as h3,
            sum(st_length(s.geom::geography)) as %I,
            %L as resolution
        from %I r, %s
        where s.geom is not null
        group by h3',
        output_h3_table,          -- %I for the output table name
        res,                      -- %s for resolution        
        output_length_field_name, -- %I for the output length field name
        res,                      -- %L for resolution (number as a literal)
        input_table,              -- %I for the input table name
        source_data               -- %s inserting the string directly
    );

    execute sql;
end;
$$;
