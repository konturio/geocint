drop table if exists global_solar_atlas_ghi_h3_r8;
create table global_solar_atlas_ghi_h3_r8 as (
    select h3,
           8 as resolution,
           gsa_ghi
    from (
            select h3_lat_lng_to_cell(geom::point, 8) as h3,
            avg(val) as gsa_ghi
             from (
                     select p.geom, p.val
                     from global_solar_atlas_ghi,
                          ST_PixelAsCentroids(rast) p
                     where (p.val > 0)
                  ) z
            group by h3
         ) x
);

-- We can add additional parameters (GTI, PVOUT etc.) in future if needed

drop table if exists global_solar_atlas_h3;
create table global_solar_atlas_h3 as (
    select
        ghi.*
    from
        global_solar_atlas_ghi_h3_r8 AS ghi
);