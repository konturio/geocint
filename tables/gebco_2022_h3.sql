drop table if exists gebco_2022_h3;

create table gebco_2022_h3 as (
    select
        e.*,
        s.avg_slope_gebco_2022
    from
        gebco_2022_elevation_h3 AS e
    full join gebco_2022_slopes_h3 AS s using (h3)
    right join land_polygons_h3_r8 using (h3)
);
