drop procedure if exists linear_segments_length_to_h3;
create or replace procedure linear_segments_length_to_h3(input_table text,
                                                         output_h3_table text,
                                                         field_name text,
                                                         resolution integer default 8)
    language plpgsql
as
$$
declare
    res integer := resolution;
begin

    execute 'drop table if exists ' || output_h3_table;
    -- transform geometry to h3 hexagons
    -- remove duplicates with low admin level
    execute 'create table ' || output_h3_table || ' as (
             select h3_lat_lng_to_cell(ST_StartPoint(s.geom)::point, ' || res || ') as h3,
                    sum(ST_Length(s.geom::geography))                               as ' || field_name || ', ' || 
                    res::text || '                                                  as resolution
             from ' || input_table || ' r ,  
                  ST_DumpSegments(r.geom) s
             group by h3)';
end;
$$;
