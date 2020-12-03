alter table firms_fires2
    set (parallel_workers = 32);

drop table if exists firms_fires2_h3;
create table firms_fires2_h3 as (
    select h3_geo_to_h3(ST_SetSrid(ST_Point(longitude, latitude), 4326), 8) as h3,
           acq_datetime                                                     as datetime,
           8                                                                as resolution
    from firms_fires2
    where acq_datetime > now() - interval '13 months'
);

alter table firms_fires_h3
    set (parallel_workers = 32);

do
$$
    declare
        res integer;
    begin
        res = 8;
        while res > 0
            loop
                insert into firms_fires_h3 (h3, wildfires, resolution)
                select h3_to_parent(h3) as h3, sum(wildfires) as wildfires, (res - 1) as resolution
                from firms_fires_h3
                where resolution = res
                group by 1;
                res = res - 1;
            end loop;
    end;
$$;
