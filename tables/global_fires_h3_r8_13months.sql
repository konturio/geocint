alter table global_fires
    set (parallel_workers = 32);

drop table if exists global_fires_h3_r8_13months;
create table global_fires_h3_r8_13months as (
    select h3_geo_to_h3(ST_SetSrid(ST_Point(longitude, latitude), 4326), 8) as h3,
           acq_datetime                                                     as datetime
    from global_fires
    where acq_datetime > now() - interval '13 months'
);
