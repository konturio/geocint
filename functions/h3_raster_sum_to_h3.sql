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
    h3_geo_to_h3(ST_Transform(geom, 4326)::point, res) as h3,
    sum(val) as sum
from
    ST_PixelAsCentroids(rast)
where val != 'NaN' and val != 0
group by 1;
$$
    language sql
    immutable
    parallel safe;
