drop table if exists gebco_2020_h3;

create table gebco_2020_h3 as (
    select
        e.*,
        s.avg_slope
    from
        gebco_2020_elevation_h3 AS e
    full join gebco_2020_slopes_h3 AS s using (h3)
);
