drop table if exists worldclim_avg_temp_h3_r8;
create table worldclim_avg_temp_h3_r8 as (
    select h3,
           8    as resolution,
           worldclim_avg_temperature
    from (
            select h3_lat_lng_to_cell(geom::point, 8) as h3,
            avg(val)                                     as worldclim_avg_temperature
             from (
                      select p.geom, p.val
                      from worldclim_avg_temp,
                           ST_PixelAsCentroids(rast) p
                      where (val != 'NaN') and (val > -100) and (val < 100)
                  ) z
            group by 1
         ) x
);
create index on worldclim_avg_temp_h3_r8 (h3);

drop table if exists worldclim_min_temp_h3_r8;
create table worldclim_min_temp_h3_r8 as (
    select h3,
           8    as resolution,
           worldclim_min_temperature
    from (
            select h3_lat_lng_to_cell(geom::point, 8) as h3,
            min(val)                                     as worldclim_min_temperature
             from (
                      select p.geom, p.val
                      from worldclim_min_temp,
                           ST_PixelAsCentroids(rast) p
                      where (val != 'NaN') and (val > -100) and (val < 100)
                  ) z
            group by 1
         ) x
);
create index on worldclim_min_temp_h3_r8 (h3);

drop table if exists worldclim_max_temp_h3_r8;
create table worldclim_max_temp_h3_r8 as (
    select h3,
           8    as resolution,
           worldclim_max_temperature
    from (
            select h3_lat_lng_to_cell(geom::point, 8) as h3,
            max(val)                                     as worldclim_max_temperature
             from (
                      select p.geom, p.val
                      from worldclim_max_temp,
                           ST_PixelAsCentroids(rast) p
                      where (val != 'NaN') and (val > -100) and (val < 100)
                  ) z
            group by 1
         ) x
);
create index on worldclim_max_temp_h3_r8 (h3);

drop table if exists worldclim_temperatures_h3;
create table worldclim_temperatures_h3 as (
    select
        wc_avg.*,
        wc_min.worldclim_min_temperature,
        wc_max.worldclim_max_temperature,
        wc_max.worldclim_max_temperature - wc_min.worldclim_min_temperature as worldclim_amp_temperature
    from
        worldclim_avg_temp_h3_r8 AS wc_avg
        full join worldclim_min_temp_h3_r8 AS wc_min using (h3)
        full join worldclim_max_temp_h3_r8 AS wc_max using (h3)
);