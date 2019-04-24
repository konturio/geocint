/******************************************************************************
### ST_Pixel ###
Given an osm geometry, returns a bounding-box
geometry of the pixel equals to the tile on zoom + 8
covering centroid of the osm geometry.
__Parameters:__
- `geometry` geom - An osm object.
- `integer` zoom - A  zoom level.
- `integer` srid - SRID of the desired target projection of the bounding
  box. Defaults to 3857 (Web Mercator).
__Returns:__ `geometry(polygon)`
******************************************************************************/
create or replace function ST_Pixel(geom geometry, zoom integer, srid integer = 3857
                                   )
    returns geometry
    language plpgsql
    immutable strict parallel safe
as
$function$
declare
    z     integer;
    n     numeric;
    point geometry;
    pixel geometry;
    xTile integer;
    yTile integer;
begin
    z := zoom + 8;
    n := 2 ^ z;
    point := ST_Transform(ST_Centroid(geom), 3857);
    xTile := floor(n * ((ST_X(point) + 20037508.34) / 40075016.68));
    yTile := floor(n * ((20037508.34 - ST_Y(point)) / 40075016.68));

    pixel := TileBBox(z, xTile, yTile, srid);
    return pixel;
end;
$function$;
