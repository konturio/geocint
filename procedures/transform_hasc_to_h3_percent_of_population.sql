-- this version of transform_hasc_to_h3 procedure allows you
-- transform any indicator that represent the number of people per country
-- to percent of population
drop procedure if exists transform_hasc_to_h3_percent_of_population;
create or replace procedure transform_hasc_to_h3_percent_of_population(input_hasc_table text,
                                                 ouput_h3_table text,
                                                 hack_field_name text,
                                                 items text[],
                                                 resolution integer default 8)
    language plpgsql
as
$$
declare
    res                               integer := resolution;
    input_table                       text:= input_hasc_table;
    item_list                         text;
    column_list                       text;
    column_list_divided_to_population text;
begin
    select string_agg(format('%1$s', col), ',')
    into column_list
    from unnest(items) t(col);

    select string_agg(concat(format('%1$s', col),'::float / kontur_boundaries_population::float * 100.0::float as ',format('%1$s', col)), ',')
    into column_list_divided_to_population
    from unnest(items) t(col);

    begin
        -- drop temporary table if exists before creation
        execute 'drop table if exists ' || input_hasc_table || '_temp_in_table ';

        -- match indexes with geometry with using hasc (isoalpha2) codes
        execute 'create table ' || input_hasc_table || '_temp_in_table as (
                 select k.kontur_admin_level as admin_level, k.population as kontur_boundaries_population, k.geom as geom, ' || column_list || '
                 from kontur_boundaries k join ' || input_hasc_table || ' s
                 on s.' || hack_field_name ||' = k.hasc_wiki
                 where k.hasc_wiki in (select ' || hack_field_name ||' from ' || input_hasc_table || '))';

        -- get missed hasc codes and insert to special table kontur_boundaries_hasc_codes_check
        execute 'insert into kontur_boundaries_hasc_codes_check (missed_hasc, source_of_missed_hasc, found_at)
                    (select distinct s.' || hack_field_name ||' as missed_hasc, 
                                     ''' || input_table || ''' as source_of_missed_hasc,
                                     NOW()                      as found_at
                    from ' || input_hasc_table || ' s, kontur_boundaries k
                    where s.' || hack_field_name ||' not in (select hasc_wiki from kontur_boundaries where hasc_wiki is not null))';

        
        execute 'drop table if exists ' || ouput_h3_table;

        -- transform geometry to h3 hexagons
        -- remove duplicates with low admin level
        execute 'create table ' || ouput_h3_table || ' as (
                 select distinct on (h3) h3_polygon_to_cells(ST_Subdivide(geom), ' || res || ') as h3,' || 
                 column_list_divided_to_population || ', ' || res::text || ' as resolution
                 from ' || input_hasc_table || '_temp_in_table
                 order by h3, admin_level desc)';

        -- drop temporary table
        execute 'drop table if exists ' || input_hasc_table || '_temp_in_table ';
    end;
end;
$$;
