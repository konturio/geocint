drop table if exists gebco_h3;

create table gebco_h3 as (
    select
        e.*,
        s.avg_slope_gebco
    from
        gebco_elevation_h3 AS e
    full join gebco_slopes_h3 AS s using (h3)
);
