drop function if exists calculate_h3_res(z integer
);

create or replace function calculate_h3_res
(
    z integer
)
    returns table (
        tile_resolution integer,
        zoom_lvl        integer
    )
    returns null on null input
    language plpgsql immutable
as
$func$
begin
    if z < 8 then
        return query
            with h3_resolutions as (
                select i as id, h3_get_hexagon_edge_length_avg(i, 'm') as edge_length from generate_series(0, 15) i
            )
            select least((
                             select id
                             from h3_resolutions
                             order by abs(40075016.6855785 / (256 * 2 ^ z) * 22 - edge_length)
                             limit 1 ),
                         8) as tile_resolution,
                   z as zoom_lvl;
    else
        return query
            with h3_resolutions as (
                select i as id, h3_get_hexagon_edge_length_avg(i, 'm') as edge_length from generate_series(0, 15) i
            )
            select least((
                             select id
                             from h3_resolutions
                             order by abs(40075016.6855785 / (256 * 2 ^ i) * 22 - edge_length)
                             limit 1
                         ), 8) as tile_resolution,
                   i as zoom_lvl
            from generate_series(8, 12) i;
    end if;
end;
$func$;

