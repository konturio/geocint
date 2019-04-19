create or replace function ST_SnapToCellGrid(geom geometry,
                                             zoom integer
                                            )
    returns geometry
    language sql
    immutable strict parallel safe
as
$function$
-- size formula 40075016.68 / 256 * 2 ^ zoom
select
    ST_Expand(ST_SnapToGrid(ST_Transform(ST_Centroid(geom), 3857), 40075016.68 / 256 * 2 ^ zoom),
              (40075016.68 / 256 * 2 ^ zoom) / 2);

$function$;