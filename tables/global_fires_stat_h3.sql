set timezone to 'UTC';

drop table if exists global_fires_stat_h3;
create table global_fires_stat_h3 as (
    select h3_lat_lng_to_cell(ST_SetSrid(ST_Point(longitude, latitude), 4326), 8) as h3,
           count(distinct date_trunc('day', acq_datetime))                  as wildfires,
           array_agg(distinct date_trunc('day', acq_datetime))              as days_array,
           8                                                                as resolution
    from global_fires
    group by 1
);

do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into global_fires_stat_h3 (h3, wildfires,  days_array, resolution)
                select h3_cell_to_parent(h3) as h3,
 	                count(distinct days)  as wildfires,
                    array_agg(distinct days) as days_array,
                    (res - 1) as resolution
                from global_fires_stat_h3, unnest(days_array) as days
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;
