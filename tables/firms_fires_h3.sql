drop table if exists firms_fires_h3;
create table firms_fires_h3 as (
    select distinct acq_datetime,
                    h3_geo_to_h3(ST_SetSrid(ST_Point(longitude, latitude), 4326), 8) as h3
    from firms_fires
);

drop table firms_fires_h3_r8;
create table firms_fires_h3_r8 as (
    select count(*) as wildfires,
           h3_geo_to_h3(ST_SetSrid(ST_Point(longitude, latitude), 4326), 6) as h3
    from firms_fires
    group by 2
);

drop table if exists firms_fires_h3_r6_geom;
create table firms_fires_h3_r6_geom as (
    select h3_to_geo_boundary_geometry(h3) as geom,
           fires
    from firms_fires_h3_r6
);
