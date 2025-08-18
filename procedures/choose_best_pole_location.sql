-- choose best n locations for pole placement
drop procedure if exists choose_best_pole_location;
create or replace procedure choose_best_pole_location(

    input_table text, -- source table with points
    output_table text, -- output table for selected points
    number_points integer, -- number of points to choose
    entry_range float[] default array[1609.3,3218.6] -- array with near and far distances limiting choice
                                                     -- by default choose points between 1 and 2 miles

)
language plpgsql
as
-- choose best n locations
$$
declare
    counter integer := 1;
begin

    execute 'drop table if exists ' || output_table;

    -- choose seed point for the first cluster
    execute 'create table ' || output_table || ' as (
        select * from ' || input_table || ' where rank = 1
    )';

    -- initialize first neighbors with distance to seed pole
    execute 'update ' || input_table || ' g
    set dist_network = ST_Distance(g.geog,k.geog)
    from (select geog from ' || output_table || ') k
    where ST_DWithin(g.geog,k.geog, ' || entry_range[2] || ')';

    while counter < number_points loop

        execute 'insert into ' || output_table || ' (select source,
                                                            id,
                                                            cost,
                                                            dist_network,
                                                            ' || counter + 1 || ',
                                                            geog
                                                     from ' || input_table || '
                                                     where dist_network > ' || entry_range[1] || '
                                                     order by cost desc limit 1)';

        -- update distance for new neighbors
        execute 'update ' || input_table || ' g
        set dist_network = ST_Distance(g.geog,k.geog)
        from (select ST_Collect(geog::geometry)::geography as geog
              from ' || output_table || ') k
        where ST_DWithin(g.geog,k.geog, ' || entry_range[2] || ')';

        counter := counter + 1;

    end loop;
end;
$$;

-- call example:  call choose_best_pole_location ('testcity_candidates_copy', 'proposed_points_3_scenario', 30, '{1608.3,3216.6}'::float[]);
