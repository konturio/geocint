-- The procedure calculates the total length of line-like objects inside each H3 cell.
-- It supports two modes:  
--   • 'dump'            – simply dumps the stored line geometry into individual
--                         segments; faster, but can leave gaps at high resolutions.  
--   • 'split_and_dump'  – first segmentizes each line to a given segment length
--                         (in metres) and then dumps the pieces; slower but yields
--                         more complete coverage at finer H3 resolutions.
--
-- Usage examples
-- --------------
-- call linear_segments_length_to_h3(
--         'roads',          -- source table
--         'roads_h3_r8',    -- output table
--         'dump',           -- mode
--         'road_length',    -- output length column
--          8                -- resolution
-- );
--
-- call linear_segments_length_to_h3(
--         'roads',
--         'roads_h3_r8_sg',
--         'split_and_dump',
--         'road_length',
--          8,
--         25,               -- split length (metres)
--         'seg_geom'        -- source geometry column (optional, default 'geom')
-- );

create or replace procedure linear_segments_length_to_h3(
    input_table              text,
    output_h3_table          text,
    mode                     text,                     -- 'dump' | 'split_and_dump'
    output_length_field_name text,                     -- name of length column in the result
    resolution               integer          default 8,
    split_distance           double precision default 25,
    geometry_column          text             default 'geom'  -- optional geometry field
)
language plpgsql
as $$
declare
    res         integer := resolution;
    source_data text;  -- fragment that returns the segments to aggregate
    sql         text;
begin
    --------------------------------------------------------------------------
    -- 1. Build the segment-producing expression depending on the chosen mode
    --------------------------------------------------------------------------
    if mode = 'dump' then
        -- Plain dump of the stored line geometry to its constituent segments
        source_data := format(
            'ST_DumpSegments(r.%I) s',
            geometry_column
        );

    elsif mode = 'split_and_dump' then
        -- First segmentize to the requested spacing, then dump the pieces
        source_data := format(
            'ST_DumpSegments(' ||
            'ST_Segmentize(r.%I::geography, %s)::geometry' ||
            ') s',
            geometry_column,
            split_distance
        );

    else
        raise exception
            'Invalid "mode". Allowed values: dump, split_and_dump';
    end if;

    --------------------------------------------------------------------------
    -- 2. Drop existing output table (if any) and create a fresh one
    --------------------------------------------------------------------------
    execute format('drop table if exists %I', output_h3_table);

    sql := format($f$
        create table %I as
        select
            -- Hexagon index taken from the start point of each segment
            h3_lat_lng_to_cell(ST_StartPoint(s.geom)::point, %s) as h3,
            -- Total length (metres) of segments falling in that cell
            sum(ST_Length(s.geom::geography))                    as %I,
            -- Store the resolution just for convenience
            %L::integer                                          as resolution
        from %I r, %s
        where s.geom is not null
        group by h3
    $f$,
        output_h3_table,        -- %I  output table name
        res,                    -- %s  resolution value in H3 function
        output_length_field_name,  -- %I  name for aggregated length column
        res,                    -- %L  literal resolution stored in the table
        input_table,            -- %I  source table
        source_data             -- %s  segment-generating expression
    );

    execute sql;
end;
$$;
