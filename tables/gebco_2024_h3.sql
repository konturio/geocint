drop table if exists gebco_2024_h3;

create table gebco_2024_h3 as (
    select
        e.*,
        s.avg_slope_gebco_2024
    from
        gebco_2024_elevation_h3 AS e
    full join gebco_2024_slopes_h3 AS s using (h3)
);
