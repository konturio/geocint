alter table firms_fires
    set (parallel_workers = 32);

drop table if exists firms_fires_h3_13_months;
create table firms_fires_h3_13_months as (
    select h3_geo_to_h3(ST_SetSrid(ST_Point(longitude, latitude), 4326), 8) as h3,
           acq_datetime                                                     as datetime,
           8                                                                as resolution
    from firms_fires
    where acq_datetime > now() - interval '13 months'
);
