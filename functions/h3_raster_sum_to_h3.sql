create or replace function h3_raster_sum_to_h3
(
    rast raster, res int
)
    returns table (
        h3  h3index,
        sum float
    )
as $$
select
    h3_geo_to_h3(p, res) as h3,
    sum(val) as sum
from
    ST_PixelAsPolygons(rast),
    cast(ST_Transform(geom, 4326)::box as point) p
where val != 'NaN' and val != 0
and p != '(Infinity, Infinity)'
group by 1;
$$
    language sql
    immutable
    parallel safe;
