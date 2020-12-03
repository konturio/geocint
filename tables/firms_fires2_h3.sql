alter table firms_fires2
    set (parallel_workers = 32);

drop table if exists firms_fires2_h3;
create table firms_fires2_h3 as (
    select h3_geo_to_h3(ST_SetSrid(ST_Point(longitude, latitude), 4326), 8) as h3,
           acq_datetime                                                     as datetime
    from firms_fires
    where acq_datetime > now() - interval '13 months'
);
