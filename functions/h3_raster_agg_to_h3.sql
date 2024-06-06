create or replace function h3_raster_agg_to_h3
(
    rast raster, 
    res int,
    agregate_function text default 'sum'
)
    returns table (
        h3  h3index,
        value float
    )
as $$
select
    h3_lat_lng_to_cell(
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
    case
        when agregate_function = 'avg'
            then avg(val)
        when agregate_function = 'count'
            then count(val)
        when agregate_function = 'min'
            then min(val)
        when agregate_function = 'max'
            then max(val)
        else sum(val)
    end as value
from
    ST_PixelAsPolygons(rast)
where val != 'NaN' and val != 0
group by 1;
$$
    language sql
    immutable
parallel safe;