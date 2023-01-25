drop function if exists tile_zoom_level_to_h3_resolution(z numeric, hex_edge_pixels numeric, tile_size integer, max_h3_resolution integer);

create or replace function tile_zoom_level_to_h3_resolution
(
    z numeric,                           -- input tile zoom level
    hex_edge_pixels numeric default 44,  -- how many pixels should be presented by the average hex edge
    tile_size integer default 512,       -- which tile size in pixels is used
    max_h3_resolution integer default 15 -- for cases when there are limits on max h3 resolution allowed
)
    returns integer                      -- output optimal h3 resolution
    returns null on null input
    language plpgsql immutable
as
$func$
begin
    -- tile zoom level couldn't be negative
    if z < 0 then
        raise exception 'Tile zoom level could not be negative';
    end if;

    return (
    with h3_resolutions as (
                -- list of average hexagon edge lengths at all h3 resolutions (0-15)
                select i as id, h3_get_hexagon_edge_length_avg(i, 'm') as edge_length from generate_series(0, 15) i
            )
            select least((
                             select id
                             from h3_resolutions
                             -- calculate single pixel length at given tile zoom level, multiply it on desired hex edge size in pixels
                             -- and compare with hexagon edge length at each resolution. Select optimal
                             order by abs(40075016.6855785 / (tile_size * 2 ^ (z)) * hex_edge_pixels - edge_length)
                             limit 1),
                         -- force given max_h3_resolution if calculated is greater
                         max_h3_resolution) as h3_resolution);
end;
$func$;