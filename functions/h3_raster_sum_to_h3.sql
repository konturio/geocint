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
    h3_geo_to_h3(
        case
            when ST_SRID(geom) = 4326  then
                -- 4326 is what H3 wants
                geom::box::point
            when ST_SRID(geom) = 54009 then
                -- 54009 Molleweide has some pixels that end up on infinity, take their corner closer to center
                ST_Transform(ST_ClosestPoint(geom, 'SRID=54009;POINT(0 0)'), 4326)::point
            else
                -- 3395, 3857 don't need special care and we don't have more hacks for now
                ST_Transform(geom, 4326)::box::point
        end,
        res
        ) as h3,
    sum(val) as sum
from
    ST_PixelAsPolygons(rast)
where val != 'NaN' and val != 0
group by 1;
$$
    language sql
    immutable
    parallel safe;
