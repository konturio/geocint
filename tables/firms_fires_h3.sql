drop table if exists firms_fires_h3;
create table firms_fires_h3 as (
    select distinct acq_datetime,
                    h3_geo_to_h3(ST_SetSrid(ST_Point(longitude, latitude), 4326), 8) as h3
    from firms_fires
);
